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
# On a full run it also cross-checks the human-facing WORKFLOW.md map against the
# skills it names — skill names, `<kit> <mode>` invocations, and lifecycle labels
# must still exist in the source SKILL.md files (error), so the map breaks loudly
# instead of rotting when a mode or label is renamed.
# Usage: scripts/lint.sh [skill-name ...]   (default: all skills + WORKFLOW.md)
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
    if ! printf '%s' "$fname" | grep -qE '^[a-z][a-z0-9]*kit$'; then
      issues+=("W:name not a lowercase word ending in 'kit'")
    fi
  fi

  # description front-loads a "Use when" trigger
  if ! printf '%s\n' "$fm" | grep -qi '^description:'; then
    issues+=("E:no description: field")
  else
    desc_has="$(printf '%s\n' "$fm" | grep -ci 'use when' || true)"
    [[ "$desc_has" -eq 0 ]] && issues+=("W:description missing 'Use when' trigger")
  fi

  # license present
  printf '%s\n' "$fm" | grep -qi '^license:' || issues+=("W:no license: field")

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
    if grep -qE '\]\(\.\.?/' "$file"; then
      issues+=("W:public skill has a repo-relative link (../…) — won't resolve once installed")
    fi
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
#   - the lifecycle label map: issuekit ↔ repokit (names + colors must match;
#     the meaning columns intentionally differ in wording)
#   - the commit-type table: commitkit ↔ issuekit (issuekit adds `epic`)
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
            <(type_tokens "$SKILLS_DIR/issuekit/SKILL.md" | grep -vx 'epic') \
        | grep -E '^[<>]' || true)"
  [[ -n "$d" ]] && while IFS= read -r line; do
    tissues+=("type table drift (commitkit '<' vs issuekit '>', epic excluded): ${line}")
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
# mode WORKFLOW.md names should show up inside a code span in its own skill.
skill_backtick_has_word() {
  local kit="$1" word="$2" f="$SKILLS_DIR/$kit/SKILL.md"
  [[ -f "$f" ]] || return 1
  grep -oE '`[^`]+`' "$f" | grep -qwF -- "$word"
}

# Cross-check the human-facing WORKFLOW.md map against the skills it describes.
# It duplicates skill facts on purpose — modes, labels, names — so a reader gets
# one map; nothing else keeps it honest, so guard the three that rot on a rename:
#   A. every `kit` skill it names still exists as a skill directory
#   B. every `<kit> <mode>` invocation names a mode that skill actually defines
#   C. every lifecycle label in the vocabulary section still lives in issuekit
# Cheap greps over backtick spans — a loud tripwire, not a proof. Full runs only.
check_workflow_doc() {
  local doc="$REPO_ROOT/WORKFLOW.md"
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
    echo "  ${C_GREEN}✓${C_RESET} WORKFLOW.md"
    return
  fi
  echo "  ${C_RED}✗${C_RESET} WORKFLOW.md"
  local i
  for i in "${wissues[@]}"; do
    echo "      ${C_RED}error:${C_RESET} ${i}"; errors=$((errors + 1))
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

echo
echo "${C_DIM}${errors} error(s), ${warns} warning(s)${C_RESET}"
[[ "$errors" -eq 0 ]]
