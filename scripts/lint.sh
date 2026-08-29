#!/usr/bin/env bash
# Check each skill against the repo conventions in AGENTS.md:
#   - SKILL.md exists with a YAML frontmatter block
#   - name: field matches the directory name exactly
#   - name is one lowercase word ending in `kit`
#   - description front-loads a "Use when" trigger
#   - license: is present
#   - metadata.internal: true|false is declared (visibility marker)
#   - public skills (internal:false) look portable (no repo-relative links / repo machinery)
#   - every intra-doc [..](#anchor) link resolves to a real heading (error)
#   - no number-based "step N", "step-N", or "§N" cross-references — they rot on reorder (warn)
#   - a closing hand-off section exists, so the skill recaps and routes (warn)
# On a full run it also checks that every skill has a reader-facing wiki page
# under docs/wiki/skills/ and that the modes each page documents still exist.
# On a full run it also cross-checks the human-facing docs/wiki/workflow.md map
# against the skills it names — skill names, `<kit> <mode>` invocations, and
# lifecycle labels must still exist in the source SKILL.md files (error), so the
# map breaks loudly instead of rotting when a mode or label is renamed.
# Usage: scripts/lint.sh [skill-name ...]   (default: all skills + the workflow map)
# Exit status is non-zero if any errors (not warnings) were found.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

errors=0
warns=0

# Extract the top YAML frontmatter block (between the first two `---` lines).
frontmatter() {
  awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$1"
}

# Verify reference integrity within a SKILL.md. Builds the set of GitHub heading
# anchors (matching github-slugger: lowercase, drop punctuation, spaces→hyphens,
# no hyphen-collapse, duplicate slugs get -1/-2 suffixes) and checks every
# intra-doc [..](#anchor) link against it. Also flags number-based step/section
# references: those bind to a step's *position*, so reordering silently points
# them at the wrong step — a named anchor link binds to identity instead and
# breaks loudly here if the heading moves or is renamed. Code fences are skipped.
# Emits TAB-separated  <E|W>\t<line>\t<message>  rows.
check_anchors() {
  LC_ALL=C awk '
    function slug(h,   s) {
      s = tolower(h)
      gsub(/[^a-z0-9 _-]/, "", s)
      gsub(/ /, "-", s)
      return s
    }
    /^```/ || /^~~~/ { infence = !infence; next }
    infence { next }
    /^#+[ \t]/ {
      h = $0
      sub(/^#+[ \t]+/, "", h)
      s = slug(h)
      if (s in seen) { cnt[s]++; s = s "-" cnt[s] } else { seen[s] = 1 }
      anchors[s] = 1
      next
    }
    {
      line = $0
      while (match(line, /\]\(#[^)]+\)/)) {
        a = substr(line, RSTART + 3, RLENGTH - 4)   # strip leading ](#  and trailing )
        nlink++; lln[nlink] = FNR; lan[nlink] = a
        line = substr(line, RSTART + RLENGTH)
      }
      if (match($0, /[Ss]teps?([ ]+#?|-)[0-9]+|§[0-9]+/)) {
        nstep++; sln[nstep] = FNR; stx[nstep] = substr($0, RSTART, RLENGTH)
      }
    }
    END {
      for (i = 1; i <= nlink; i++)
        if (!(lan[i] in anchors))
          printf "E\t%d\tbroken intra-doc anchor: #%s\n", lln[i], lan[i]
      for (i = 1; i <= nstep; i++)
        printf "W\t%d\tnumber-based step reference \"%s\" — use a named anchor link\n", sln[i], stx[i]
    }
  ' "$1"
}

# Skills exempt from the closing hand-off requirement, by design rather than by
# oversight: gitkit is the primitives layer other skills call, and states outright
# that preparing a worktree implies nothing about what to do in it.
HANDOFF_EXEMPT=" gitkit "

# Skills allowed to declare no `allowed-tools`. Empty on purpose: every skill
# here now declares its built-in surface, including verifykit, which depends on a
# host-supplied browser MCP and declares the four built-ins it drives itself while
# naming the MCP requirement in its Notes. The list stays as a mechanism, not a
# habit — adding a name to it means writing the reason in that skill's Notes too.
# Only *presence* is checked. Whether a declared list matches what the skill
# actually does is a read, not a grep — a heuristic for "does this invoke a
# sibling" would misfire on every skill that routes without invoking.
TOOLS_EXEMPT=" "

# Does the skill close with a hand-off — a recap of what it did plus the next move?
# (AGENTS.md § "Closing a skill: the hand-off".) `Hand off` is canonical; the rest
# are grandfathered headings from skills written before the convention. This can
# only check that such a section *exists* — whether its three beats are any good
# is a review judgment, not something a grep can settle. Code fences are skipped.
has_closing_section() {
  awk '
    /^```/ || /^~~~/ { infence = !infence; next }
    infence { next }
    /^#+[ \t]/ {
      h = tolower($0)
      sub(/^#+[ \t]+/, "", h)
      if (h ~ /hand[ -]?off|hand over|report|output|finish|after creating/) found = 1
    }
    END { exit !found }
  ' "$1"
}

check_skill() {
  local name="$1" file="$SKILLS_DIR/$1/SKILL.md" fm fname desc_has

  if [[ ! -f "$file" ]]; then
    echo "  ${C_RED}✗${C_RESET} $name — no SKILL.md"; errors=$((errors + 1)); return
  fi

  fm="$(frontmatter "$file")"
  if [[ -z "$fm" ]]; then
    echo "  ${C_RED}✗${C_RESET} $name — missing/empty frontmatter"; errors=$((errors + 1)); return
  fi

  local issues=()

  # name matches directory
  fname="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1 | tr -d '"'"'"' ')"
  if [[ -z "$fname" ]]; then
    issues+=("E:no name: field")
  elif [[ "$fname" != "$name" ]]; then
    issues+=("E:name '$fname' != dir '$name'")
  fi

  # kit suffix, one lowercase word
  if [[ -n "$fname" ]]; then
    if ! grep -qE '^[a-z][a-z0-9]*kit$' <<<"$fname"; then
      issues+=("W:name not a lowercase word ending in 'kit'")
    fi
  fi

  # description front-loads a "Use when" trigger
  if ! grep -qi '^description:' <<<"$fm"; then
    issues+=("E:no description: field")
  else
    desc_has="$(printf '%s\n' "$fm" | grep -ci 'use when' || true)"
    [[ "$desc_has" -eq 0 ]] && issues+=("W:description missing 'Use when' trigger")
  fi

  # license present
  grep -qi '^license:' <<<"$fm" || issues+=("W:no license: field")

  # allowed-tools declared — several skills lean on the field as a real backstop
  # (researchkit withholds the shell so a host that honors it can't run a spike),
  # so an undeclared surface is worth flagging rather than assuming permissive.
  if [[ "$TOOLS_EXEMPT" != *" $name "* ]]; then
    grep -qi '^allowed-tools:' <<<"$fm" \
      || issues+=("W:no allowed-tools: field — declare the tool surface, or add the skill to TOOLS_EXEMPT with the reason in its Notes")
  fi

  # visibility marker: metadata.internal must be declared true|false
  local internal_val
  internal_val="$(printf '%s\n' "$fm" | sed -n 's/^[[:space:]]*internal:[[:space:]]*//p' | head -1 | tr -d '"'"'"' ')"
  if [[ -z "$internal_val" ]]; then
    issues+=("E:no metadata.internal: true|false marker (declare internal vs public)")
  elif [[ "$internal_val" != "true" && "$internal_val" != "false" ]]; then
    issues+=("E:metadata.internal must be true or false (got '$internal_val')")
  fi

  # public skills (internal:false) must be portable / self-contained
  if [[ "$internal_val" == "false" ]]; then
    # `](../…)` escapes the skill directory and breaks once installed. `](./x.md)`
    # does not: a satellite file inside the skill's own directory ships with it,
    # and AGENTS.md's disclosure ladder calls for exactly that pointer. Flag the
    # first, allow the second, and check the second actually resolves.
    if grep -qE '\]\(\.\./' "$file"; then
      issues+=("W:public skill has a repo-relative link (../…) — won't resolve once installed")
    fi
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      [[ -e "$SKILLS_DIR/$1/$rel" ]] \
        || issues+=("E:pointer to ./$rel, but skills/$1/$rel does not exist")
    done < <(grep -oE '\]\(\./[^)#]+' "$file" | sed 's/^](\.\///' | sort -u)
    if grep -qiE '\bmake (lint|link|unlink|list)\b|AGENTS\.md|(^|[^.])scripts/' "$file"; then
      issues+=("W:public skill references repo machinery (make/AGENTS.md/scripts) — keep it self-contained")
    fi
  fi

  # closing hand-off: recap what changed, then name the next move
  if [[ "$HANDOFF_EXEMPT" != *" $name "* ]] && ! has_closing_section "$file"; then
    issues+=("W:no closing section — end with '## Hand off' (what changed · where it landed · next)")
  fi

  # reference integrity: intra-doc anchors resolve; no number-based step refs
  local _sev _ln _msg
  while IFS=$'\t' read -r _sev _ln _msg; do
    [[ -z "${_sev:-}" ]] && continue
    if [[ "$_sev" == "E" ]]; then
      issues+=("E:$_msg (line $_ln)")
    else
      issues+=("W:$_msg (line $_ln)")
    fi
  done < <(check_anchors "$file")

  if [[ ${#issues[@]} -eq 0 ]]; then
    echo "  ${C_GREEN}✓${C_RESET} $name"
    return
  fi

  local mark="${C_YELLOW}!${C_RESET}" has_err=0 i
  for i in "${issues[@]}"; do [[ "$i" == E:* ]] && has_err=1; done
  [[ "$has_err" -eq 1 ]] && mark="${C_RED}✗${C_RESET}"
  echo "  $mark $name"
  for i in "${issues[@]}"; do
    if [[ "$i" == E:* ]]; then
      echo "      ${C_RED}error:${C_RESET} ${i#E:}"; errors=$((errors + 1))
    else
      echo "      ${C_YELLOW}warn:${C_RESET}  ${i#W:}"; warns=$((warns + 1))
    fi
  done
}

# --- Shared-contract tables -------------------------------------------------
# Two tables are deliberately duplicated across public skills (each must stand
# alone once installed, so neither pair can point at a single source file):
#   - the label maps, lifecycle and priority: issuekit ↔ repokit (names +
#     colors must match; the meaning columns intentionally differ in wording).
#     Both namespaces are covered by one diff — the rows share a format, so
#     label_pairs picks up all of them without caring which table they sit in.
#   - the commit-type table: commitkit ↔ issuekit (identical sets)
# Nothing else keeps the copies aligned, so diff them here on full runs.

# Emit "name color" pairs from a SKILL.md's label table rows
# (`| `label` | `RRGGBB` | … |`).
label_pairs() {
  grep -oE '^\| *`[a-z-]+` *\| *`[0-9A-Fa-f]{6}` *\|' "$1" \
    | sed -E 's/^\| *`([a-z-]+)` *\| *`([0-9A-Fa-f]{6})` *\|.*/\1 \2/' | sort -u
}

# Emit the type tokens from a SKILL.md's commit-type table: backticked words in
# the first cell of rows whose second cell is prose (not a 6-hex color, which
# would be the label map).
type_tokens() {
  awk -F'|' '/^\|/ { c1 = $2; c2 = $3
      if (c1 ~ /`[a-z]+`/ && c2 !~ /`[0-9A-Fa-f]{6}`/) print c1 }' "$1" \
    | grep -oE '`[a-z]+`' | tr -d '`' | sort -u
}

check_shared_tables() {
  local tissues=() d
  d="$(diff <(label_pairs "$SKILLS_DIR/issuekit/SKILL.md") \
            <(label_pairs "$SKILLS_DIR/repokit/SKILL.md") | grep -E '^[<>]' || true)"
  [[ -n "$d" ]] && while IFS= read -r line; do
    tissues+=("label map drift (issuekit '<' vs repokit '>'): ${line}")
  done <<<"$d"

  d="$(diff <(type_tokens "$SKILLS_DIR/commitkit/SKILL.md") \
            <(type_tokens "$SKILLS_DIR/issuekit/SKILL.md") \
        | grep -E '^[<>]' || true)"
  [[ -n "$d" ]] && while IFS= read -r line; do
    tissues+=("type table drift (commitkit '<' vs issuekit '>'): ${line}")
  done <<<"$d"

  if [[ ${#tissues[@]} -eq 0 ]]; then
    echo "  ${C_GREEN}✓${C_RESET} shared tables (label map · type table)"
    return
  fi
  echo "  ${C_RED}✗${C_RESET} shared tables"
  local i
  for i in "${tissues[@]}"; do
    echo "      ${C_RED}error:${C_RESET} ${i}"; errors=$((errors + 1))
  done
}

# Does a whole `word` appear inside any backtick span of a skill's SKILL.md?
# Modes in this collection are written backticked (`create`, `list`, `fix`), so a
# mode the workflow map names should show up inside a code span in its own skill.
skill_backtick_has_word() {
  # Separate statements on purpose: bash 3.2 does not expose an earlier name to
  # a later initializer in the *same* `local`, so a one-line form dies under
  # `set -u` with "kit: unbound variable" on macOS's system bash.
  local kit="$1" word="$2"
  local f="$SKILLS_DIR/$kit/SKILL.md"
  [[ -f "$f" ]] || return 1
  # Buffer the spans instead of piping straight into `grep -q`. Under
  # `set -o pipefail`, a `grep -q` that matches early exits before the upstream
  # `grep -oE` finishes writing, the upstream dies of SIGPIPE (141), and pipefail
  # reports that as the pipeline's status — so a *successful* match intermittently
  # read as a failure. It surfaced as phantom "defines no such mode" errors on
  # whichever skill happened to lose the race, most often the longest ones.
  local spans
  spans="$(grep -oE '`[^`]+`' "$f" || true)"
  grep -qwF -- "$word" <<<"$spans"
}

# Cross-check the human-facing workflow map against the skills it describes.
# It duplicates skill facts on purpose — modes, labels, names — so a reader gets
# one map; nothing else keeps it honest, so guard the three that rot on a rename:
#   A. every `kit` skill it names still exists as a skill directory
#   B. every `<kit> <mode>` invocation names a mode that skill actually defines
#   C. every lifecycle label in the vocabulary section still lives in issuekit
# Cheap greps over backtick spans — a loud tripwire, not a proof. Full runs only.
check_workflow_doc() {
  local doc="$REPO_ROOT/docs/wiki/workflow.md"
  [[ -f "$doc" ]] || return 0
  local wissues=() kit mode pair lbl

  # A. skill names it references must resolve to a real skill directory
  while IFS= read -r kit; do
    [[ -z "$kit" ]] && continue
    skill_exists "$kit" || wissues+=("names skill '$kit', which has no skills/$kit/SKILL.md")
  done < <(grep -oE '`[^`]+`' "$doc" | grep -oE '[a-z][a-z0-9]*kit' | sort -u)

  # B. `<kit> <mode>` invocations must name a mode the skill actually defines
  while IFS= read -r pair; do
    [[ -z "$pair" ]] && continue
    kit="${pair%% *}"; mode="${pair#* }"
    skill_exists "$kit" || continue        # a missing skill is already flagged in A
    skill_backtick_has_word "$kit" "$mode" \
      || wissues+=("invokes '$kit $mode', but skills/$kit/SKILL.md defines no such mode")
  done < <(
    grep -oE '`[^`]+`' "$doc" | sed 's/`//g' \
      | awk '{ kit = $1; mode = $2
               if (kit !~ /^[a-z][a-z0-9]*kit$/) next
               gsub(/[^a-z-].*$/, "", mode)
               if (mode == "") next
               print kit " " mode }' \
      | sort -u
  )

  # C. lifecycle labels named in the vocabulary section must still exist in issuekit
  while IFS= read -r lbl; do
    [[ -z "$lbl" ]] && continue
    grep -qF -- "$lbl" "$SKILLS_DIR/issuekit/SKILL.md" \
      || wissues+=("vocabulary label '$lbl' is gone from issuekit/SKILL.md")
  done < <(
    awk '/^### The label vocabulary/ { inl = 1; next }
         inl && /^###? / { inl = 0 }
         inl { print }' "$doc" \
      | grep -oE '`[^`]+`' | sed 's/`//g' \
      | grep -E '^[a-z][a-z-]+$' | grep -vE 'kit$' | sort -u
  )

  if [[ ${#wissues[@]} -eq 0 ]]; then
    echo "  ${C_GREEN}✓${C_RESET} docs/wiki/workflow.md"
    return
  fi
  echo "  ${C_RED}✗${C_RESET} docs/wiki/workflow.md"
  local i
  for i in "${wissues[@]}"; do
    echo "      ${C_RED}error:${C_RESET} ${i}"; errors=$((errors + 1))
  done
}

# Cross-check the per-skill wiki pages against the skills they document. Each
# skill has a reader-facing page under docs/wiki/skills/ that duplicates skill
# facts on purpose — a reader gets one page per skill without reading SKILL.md —
# so nothing else keeps it honest. Guard the two ways it rots:
#   A. every skill has a page, and every page documents a real skill
#   B. every `### `mode`` heading on a page names a mode that skill defines
#   D. every skill is registered in docs/wiki/.wikimap.yaml, and every skill the
#      map names is real
#   E. every skill is linked from docs/wiki/index.md, and every skill the index
#      links is real
# (B) mirrors check_workflow_doc's mode check: modes in this collection are
# written backticked, so a mode a page documents should appear inside a code
# span in its own SKILL.md. A page whose mode headings aren't backticked (a
# skill whose modes genuinely aren't, like implementkit's) is simply not checked
# — the heading style is the opt-in. Full runs only.
#
# (D) is the one a human can't catch by reading. A page missing from the doc map
# looks complete from every angle — it renders, it's linked, `make lint` was
# green — and the only symptom is that later docs audits never sweep it, which
# surfaces months later as a page nobody noticed had gone stale. It was missed on
# three consecutive skills before this check existed.
#
# (E) guards the same shape one layer out: a page that exists but that no reader
# can navigate to. refactorkit shipped unreachable for eight days, and debugkit
# and tutorkit each repeated it — every one of those runs passed a clean gate,
# because (A) only proves the file is on disk. Presence in the index is all this
# checks; **placement is not enforceable** — index.md groups skills by theme, and
# a skill dropped into the wrong group links just as correctly as a right one.
# So a green run still means "reachable", never "filed correctly".
SKILL_PAGES_DIR="$REPO_ROOT/docs/wiki/skills"
WIKIMAP="$REPO_ROOT/docs/wiki/.wikimap.yaml"
WIKI_INDEX="$REPO_ROOT/docs/wiki/index.md"

# The skill names the doc map registers a page for, one per line.
# Matches `  - path: skills/<name>.md`; the map's non-skill pages don't match.
wikimap_skill_names() {
  [[ -f "$WIKIMAP" ]] || return 0
  sed -n 's|^[[:space:]]*-[[:space:]]*path:[[:space:]]*skills/\([a-z0-9-]\{1,\}\)\.md[[:space:]]*$|\1|p' \
    "$WIKIMAP" | sort -u
}

# The skill names index.md links a page for, one per line. Matches the whole
# file rather than the "The skills" section: a link anywhere on the page makes
# the skill reachable, which is the property being checked.
index_skill_names() {
  [[ -f "$WIKI_INDEX" ]] || return 0
  grep -oE '\]\(\./skills/[a-z0-9-]+\.md\)' "$WIKI_INDEX" \
    | sed 's|^](\./skills/||; s|\.md)$||' | sort -u
}

# Did a *single-skill* change land without its wiki page? (warning)
#
# The habit here is to commit a skill and its page together, and it holds: 16 of
# the last 18 skill-touching commits did exactly that. The two that didn't are
# the two shapes worth telling apart — a repo-wide prose sweep that moved 21
# skills at once, where AGENTS.md says a page edit genuinely isn't owed, and a
# single-skill change that simply forgot its page, which is the real miss.
#
# So the check is scoped to commits touching exactly one skill. A prose sweep is
# then exempt *by construction* rather than by a suppression list somebody has to
# maintain — which is what keeps this from opening at 22 warnings with 21 of them
# correct to ignore, the state in which a warning gets muted and stops working.
#
# Compares commit dates, not the page's stamped SHA: the scoping already removes
# the noise that would have justified parsing stamps, and a date needs no parsing.
page_left_behind() {
  local name="$1" sdate pdate sha touched
  sdate="$(git -C "$REPO_ROOT" log -1 --format=%cd --date=short -- "skills/$name/" 2>/dev/null || true)"
  pdate="$(git -C "$REPO_ROOT" log -1 --format=%cd --date=short -- "docs/wiki/skills/$name.md" 2>/dev/null || true)"
  # Either side never committed (a brand-new skill or page) → nothing to compare.
  [[ -n "$sdate" && -n "$pdate" ]] || return 1
  [[ "$sdate" > "$pdate" ]] || return 1
  sha="$(git -C "$REPO_ROOT" log -1 --format=%H -- "skills/$name/" 2>/dev/null || true)"
  [[ -n "$sha" ]] || return 1
  touched="$(git -C "$REPO_ROOT" show --format= --name-only "$sha" 2>/dev/null \
    | sed -n 's#^skills/\([^/]*\)/.*#\1#p' | sort -u | wc -l | tr -d '[:space:]')"
  [[ "$touched" == "1" ]]
}

check_skill_pages() {
  [[ -d "$SKILL_PAGES_DIR" ]] || return 0
  local pissues=() pwarns=() name page mode mapped indexed

  # Space-padded so a `*" $name "*` match can't hit a substring of another name.
  mapped=" $(wikimap_skill_names | tr '\n' ' ')"
  indexed=" $(index_skill_names | tr '\n' ' ')"

  # A1. every skill has a page — plus D1 (registered in the map) and E1 (linked
  # from the index). All three are the same question asked of three files: can
  # this page be found — on disk, by an audit, and by a reader.
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    [[ -f "$SKILL_PAGES_DIR/$name.md" ]] \
      || pissues+=("skills/$name has no wiki page — add docs/wiki/skills/$name.md")
    if [[ -f "$WIKIMAP" && "$mapped" != *" $name "* ]]; then
      pissues+=("skills/$name is missing from docs/wiki/.wikimap.yaml — add a 'skills/$name.md' page entry so docs audits sweep it")
    fi
    if [[ -f "$WIKI_INDEX" && "$indexed" != *" $name "* ]]; then
      pissues+=("skills/$name is unreachable from docs/wiki/index.md — link it under 'The skills' as [\`$name\`](./skills/$name.md)")
    fi
  done < <(skill_names)

  # D2. every skill page the doc map names is real
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    skill_exists "$name" \
      || pissues+=("docs/wiki/.wikimap.yaml maps skills/$name.md, but skills/$name/SKILL.md is missing")
  done < <(wikimap_skill_names)

  # E2. every skill page the index links is real
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    skill_exists "$name" \
      || pissues+=("docs/wiki/index.md links skills/$name.md, but skills/$name/SKILL.md is missing")
  done < <(index_skill_names)

  for page in "$SKILL_PAGES_DIR"/*.md; do
    [[ -f "$page" ]] || continue
    name="$(basename "$page" .md)"

    # A2. every page documents a real skill
    if ! skill_exists "$name"; then
      pissues+=("docs/wiki/skills/$name.md documents no skill (skills/$name/SKILL.md is missing)")
      continue
    fi

    # B. every backticked mode heading names a mode the skill actually defines
    while IFS= read -r mode; do
      [[ -z "$mode" ]] && continue
      skill_backtick_has_word "$name" "$mode" \
        || pissues+=("docs/wiki/skills/$name.md documents mode '$mode', but skills/$name/SKILL.md defines no such mode")
    done < <(grep -oE '^### `[a-z][a-z0-9-]*`' "$page" | sed 's/^### `//; s/`$//' | sort -u)

    # C. a single-skill change that left its page behind
    if page_left_behind "$name"; then
      pwarns+=("skills/$name changed after docs/wiki/skills/$name.md — re-read the page, then re-stamp it")
    fi
  done

  if [[ ${#pissues[@]} -eq 0 && ${#pwarns[@]} -eq 0 ]]; then
    echo "  ${C_GREEN}✓${C_RESET} docs/wiki/skills/"
    return
  fi
  local mark="${C_YELLOW}!${C_RESET}"
  [[ ${#pissues[@]} -gt 0 ]] && mark="${C_RED}✗${C_RESET}"
  echo "  $mark docs/wiki/skills/"
  local i
  for i in "${pissues[@]+"${pissues[@]}"}"; do
    echo "      ${C_RED}error:${C_RESET} ${i}"; errors=$((errors + 1))
  done
  for i in "${pwarns[@]+"${pwarns[@]}"}"; do
    echo "      ${C_YELLOW}warn:${C_RESET}  ${i}"; warns=$((warns + 1))
  done
}

run_all=0
targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  run_all=1
  while IFS= read -r n; do [[ -n "$n" ]] && targets+=("$n"); done < <(skill_names)
fi

for name in "${targets[@]}"; do
  check_skill "$name"
done

# Cross-file checks only on a full run — a single-skill lint stays scoped.
[[ "$run_all" -eq 1 ]] && check_shared_tables
[[ "$run_all" -eq 1 ]] && check_workflow_doc
[[ "$run_all" -eq 1 ]] && check_skill_pages

echo
echo "${C_DIM}${errors} error(s), ${warns} warning(s)${C_RESET}"
[[ "$errors" -eq 0 ]]
