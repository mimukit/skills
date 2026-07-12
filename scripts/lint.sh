#!/usr/bin/env bash
# Check each skill against the repo conventions in AGENTS.md:
#   - SKILL.md exists with a YAML frontmatter block
#   - name: field matches the directory name exactly
#   - name is one lowercase word ending in `kit`
#   - description front-loads a "Use when" trigger
#   - license: is present
#   - metadata.internal: true|false is declared (visibility marker)
#   - public skills (internal:false) look portable (no repo-relative links / repo machinery)
# Usage: scripts/lint.sh [skill-name ...]   (default: all skills)
# Exit status is non-zero if any errors (not warnings) were found.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

errors=0
warns=0

# Extract the top YAML frontmatter block (between the first two `---` lines).
frontmatter() {
  awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$1"
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

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  while IFS= read -r n; do [[ -n "$n" ]] && targets+=("$n"); done < <(skill_names)
fi

for name in "${targets[@]}"; do
  check_skill "$name"
done

echo
echo "${C_DIM}${errors} error(s), ${warns} warning(s)${C_RESET}"
[[ "$errors" -eq 0 ]]
