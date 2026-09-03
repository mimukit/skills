#!/usr/bin/env bash
# Generate docs/wiki/cheatsheet.md — every skill and every mode, one line each.
#
# The page is derived, never hand-written. Its whole content comes from the
# reader-facing pages under docs/wiki/skills/, which AGENTS.md already obliges
# you to update whenever a skill changes:
#
#   - the skill's one-liner  → the first paragraph of docs/wiki/skills/<name>.md
#   - each mode's one-liner  → the first sentence under that page's ``### `mode` ``
#   - the order              → alphabetical, straight from the skills/ directory
#
# When a page's own prose doesn't reduce to a good row — it opens on an aside,
# or the sentence is a fragment that only reads in context — pin the row with an
# HTML comment on the page instead of bending the prose to suit this script:
#
#   ### `list`
#   <!-- cheatsheet: reports which PRs are waiting on you, in one table -->
#
# The comment renders as nothing, sits beside the text it summarizes, and keeps
# the page the single source. Put one under the `# <name>` title to pin the
# skill's own row the same way.
#
# Reading the pages rather than the SKILL.md files is deliberate: a SKILL.md
# `description` carries its triggers, so it runs three lines, while the page
# opens with a curated single sentence. One source, one edit, no new per-skill
# duty. `scripts/lint.sh` regenerates this into a temp file and diffs it against
# the committed page, so drift fails the gate instead of rotting quietly.
#
# Usage: scripts/cheatsheet.sh [--check|-o <path>]
#   (default: write docs/wiki/cheatsheet.md)
#   --check      write nothing; exit 1 if the committed page is out of date
#   -o <path>    write to <path> instead ( - for stdout )
# Kept bash 3.2 safe — no associative arrays, no `mapfile`.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PAGES_DIR="$REPO_ROOT/docs/wiki/skills"
OUT="$REPO_ROOT/docs/wiki/cheatsheet.md"
# A row longer than this reads as a paragraph, not a glance. The fix is to
# tighten the sentence on the skill page, or to pin the row with a
# `<!-- cheatsheet: … -->` comment. Reported by `make cheatsheet` only: the
# drift diff is the gate, and a length nudge firing on every lint run is a
# warning people learn to scroll past.
MAX_WORDS_MODE=25
# A skill's row is its page's opening sentence, which carries more than a mode
# row does, so it gets more room before the nudge fires.
MAX_WORDS_SKILL=40

mode=write
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) mode=check; shift ;;
    -o) OUT="$2"; shift 2 ;;
    *) die "unknown argument: $1 (usage: cheatsheet.sh [--check|-o <path>])" ;;
  esac
done

# --- extraction --------------------------------------------------------------

# The first paragraph of a page, as one line: everything after the `# <name>`
# title up to the next blank line. That paragraph is the page's one-line
# description — AGENTS.md requires every skill page to open with one.
page_summary() {
  awk '
    /^# / { seen = 1; next }
    !seen { next }
    /^<!--[ ]*cheatsheet:/ {
      s = $0
      sub(/^<!--[ ]*cheatsheet:[ ]*/, "", s); sub(/[ ]*-->.*$/, "", s)
      print s; exit
    }
    /^$/  { if (buf != "") exit; next }
    /^[|>#]/ { if (buf != "") exit; next }
    { buf = (buf == "" ? $0 : buf " " $0) }
    END { print buf }
  ' "$1"
}

# Every backticked mode on a page with its one-liner, as  <mode>\t<sentence>.
# The one-liner is the opening of the first prose paragraph under the
# ``### `mode` `` heading — tables, blockquotes and fences are skipped, so a
# mode section that opens with a table falls through to its first real sentence.
#
# Three rules turn page prose into a row, and each exists because a page in this
# collection breaks the naive version:
#   1. A paragraph opening on a bold label takes the whole bold span. wikikit's
#      `audit` opens "**Read-only. Writes nothing, ever.**" — splitting on the
#      inner period leaves a row ending in a dangling `**`.
#   2. Otherwise take the first sentence, and add the second when the first runs
#      under six words. testkit's `audit` opens "Read-only." — true, and useless
#      on its own.
#   3. A `<!-- cheatsheet: … -->` comment beats both.
page_modes() {
  awk '
    function nwords(x,   a) { return split(x, a, " ") }
    # A period followed by a space and a capital ends a sentence. `e.g.` and
    # `origin/*.` survive, because neither is followed by a capital.
    function firstsent(s) {
      if (match(s, /\.[ ]+[A-Z(`*]/)) return substr(s, 1, RSTART)
      return s
    }
    function flush(   s, out, rest, j, bold) {
      if (mode == "") return
      if (pinned != "") { print mode "\t" pinned; mode = ""; buf = ""; pinned = ""; return }
      if (buf == "") return
      s = buf; out = ""
      if (substr(s, 1, 2) == "**") {
        j = index(substr(s, 3), "**")
        if (j > 1) {
          bold = substr(s, 3, j - 1)
          if (nwords(bold) >= 3) out = bold
        }
      }
      if (out == "") {
        # Drop bold markers before splitting: a sentence ending inside emphasis
        # ("**Opt-in.** Nothing routes into it") otherwise leaves stray stars in
        # the row, and emphasis buys nothing in a one-line entry anyway.
        gsub(/\*\*/, "", s)
        out = firstsent(s)
        if (nwords(out) < 6) {
          rest = substr(s, length(out) + 1)
          sub(/^[ ]+/, "", rest)
          if (rest != "") out = out " " firstsent(rest)
        }
      }
      sub(/[ ]+$/, "", out)
      sub(/\.$/, "", out)
      print mode "\t" out
      mode = ""; buf = ""
    }
    /^```/ || /^~~~/ { infence = !infence; next }
    infence { next }
    /^### `[a-z][a-z0-9-]*`/ {
      flush()
      h = $0; sub(/^### `/, "", h); sub(/`.*$/, "", h)
      mode = h; buf = ""; pinned = ""
      next
    }
    /^#/ { flush(); mode = ""; next }
    mode == "" { next }
    /^<!--[ ]*cheatsheet:/ {
      s = $0
      sub(/^<!--[ ]*cheatsheet:[ ]*/, "", s); sub(/[ ]*-->.*$/, "", s)
      pinned = s; flush(); next
    }
    /^$/ { if (buf != "") flush(); next }
    /^[|>-]/ { next }
    { buf = (buf == "" ? $0 : buf " " $0) }
    END { flush() }
  ' "$1"
}

# Lowercase the opening letter so a sentence reads as a list row ("creates the
# worktree"), unless the first word is a code span, an acronym, or a name.
decap() {
  awk '{
    first = substr($0, 1, 1); second = substr($0, 2, 1)
    if (first ~ /[A-Z]/ && second ~ /[a-z]/) print tolower(first) substr($0, 2)
    else print
  }'
}

anchor() { echo "$1"; }  # every skill name is already a valid GitHub anchor

# A skill page links its siblings as `](./gitkit.md)`, relative to
# docs/wiki/skills/. This page sits one level up, so every borrowed link needs
# the directory back on the front or it 404s.
reroot() { sed 's|](\./|](./skills/|g'; }

warnings=()
check_length() {
  local what="$1" text="$2" limit="$3" n
  n=$(echo "$text" | wc -w | tr -d '[:space:]')
  [[ "$n" -le "$limit" ]] \
    || warnings+=("$what runs $n words — tighten the sentence on its skill page")
}

# --- rendering ---------------------------------------------------------------

# One skill block: an h2 linking its page, its one-liner, then a table of modes.
render_skill() {
  local name="$1" page="$PAGES_DIR/$1.md" summary line mode text count=0
  if [[ ! -f "$page" ]]; then
    warnings+=("$name has no page under docs/wiki/skills/ — skipped")
    return
  fi
  summary="$(page_summary "$page")"
  [[ -n "$summary" ]] || warnings+=("$name: docs/wiki/skills/$name.md has no opening description")
  check_length "$name" "$summary" "$MAX_WORDS_SKILL"

  echo "## [\`$name\`](./skills/$name.md)"
  echo
  echo "$summary" | reroot
  echo
  # Modes render as their own table, so a long row wraps inside its cell
  # instead of under the next mode's name. A pipe in the prose is escaped, or
  # it would split the cell.
  while IFS=$'\t' read -r mode text; do
    [[ -z "$mode" ]] && continue
    count=$((count + 1))
    check_length "$name \`$mode\`" "$text" "$MAX_WORDS_MODE"
    if [[ "$count" -eq 1 ]]; then
      echo '| Mode | What it does |'
      echo '|---|---|'
    fi
    printf -- '| `%s` | %s |\n' "$mode" \
      "$(printf '%s' "$text" | decap | reroot | sed 's/|/\\|/g')"
  done < <(page_modes "$page")
  # A skill with no modes is not a gap: most of the collection is single-path.
  # Say so explicitly, so a blank block never reads as a missing extraction.
  [[ "$count" -eq 0 ]] && echo "_No modes — one path._"
  echo
}

render() {
  local name summary

  cat <<'EOF'
# Cheatsheet

Every skill and every mode, one line each. This is the recall page — what exists, and what each mode does — not the explanation. For how the skills compose into one loop, read [the workflow](./workflow.md); for a skill in full, follow its name to its page.

EOF

  # The jump table: every skill in one alphabetical list, with the same one-liner
  # its section repeats. Alphabetical beats thematic here — you arrive knowing
  # the name and wanting the modes, and a theme grouping makes you find the
  # theme first. Themes still exist on the index page, which is where a reader
  # who doesn't know the name starts.
  echo '| Skill | What it does |'
  echo '|---|---|'
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    [[ -f "$PAGES_DIR/$name.md" ]] || continue
    summary="$(page_summary "$PAGES_DIR/$name.md" | reroot | sed 's/|/\\|/g')"
    printf -- '| [`%s`](#%s) | %s |\n' "$name" "$(anchor "$name")" "$summary"
  done < <(skill_names)
  echo

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    render_skill "$name"
  done < <(skill_names)

  cat <<'EOF'
---

_Generated by `make cheatsheet` from the pages under [`docs/wiki/skills/`](./skills/). Edit a skill's page, not this file — `make lint` diffs the two._
EOF
}

# --- output ------------------------------------------------------------------

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
render > "$tmp"

if [[ "$mode" != check ]]; then
  for w in "${warnings[@]+"${warnings[@]}"}"; do warn "$w"; done
fi

if [[ "$mode" == check ]]; then
  if [[ ! -f "$OUT" ]]; then
    die "docs/wiki/cheatsheet.md is missing — run 'make cheatsheet'"
  fi
  if ! diff -u "$OUT" "$tmp" > /dev/null; then
    diff -u "$OUT" "$tmp" | sed 's/^/  /' >&2 || true
    die "docs/wiki/cheatsheet.md is out of date — run 'make cheatsheet'"
  fi
  info "docs/wiki/cheatsheet.md is up to date"
  exit 0
fi

if [[ "$OUT" == "-" ]]; then
  cat "$tmp"
else
  cat "$tmp" > "$OUT"
  info "wrote ${OUT#$REPO_ROOT/}"
fi
