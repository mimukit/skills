#!/usr/bin/env bash
# Shared helpers for the mimukit/skills tooling. Source this; don't execute it.
# Kept bash 3.2 safe (macOS /bin/bash) — no associative arrays, no `mapfile`.

# --- paths -------------------------------------------------------------------
_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$_lib_dir")"
SKILLS_DIR="$REPO_ROOT/skills"
CLAUDE_SKILLS="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

# --- colors (only when stderr is a tty) --------------------------------------
if [[ -t 2 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  C_DIM="$(tput dim)"; C_RED="$(tput setaf 1)"; C_GREEN="$(tput setaf 2)"
  C_YELLOW="$(tput setaf 3)"; C_BLUE="$(tput setaf 4)"; C_RESET="$(tput sgr0)"
else
  C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_RESET=""
fi

die()  { echo "${C_RED}error:${C_RESET} $*" >&2; exit 1; }
warn() { echo "${C_YELLOW}warn:${C_RESET} $*" >&2; }
info() { echo "$*" >&2; }

# --- skill enumeration -------------------------------------------------------
# Print each skill dir name (one per line), sorted. A skill is a dir with SKILL.md.
skill_names() {
  local d
  for d in "$SKILLS_DIR"/*/; do
    [[ -f "$d/SKILL.md" ]] || continue
    basename "$d"
  done | sort
}

skill_exists() { [[ -f "$SKILLS_DIR/$1/SKILL.md" ]]; }

# Classify what's at ~/.claude/skills/<name>:
#   linked    — symlink pointing at our copy (a dev link we own)
#   foreign   — symlink pointing somewhere else
#   real      — a real file/dir (e.g. a skills.sh install) — do not touch
#   unlinked  — nothing there
link_status() {
  local name="$1" dest="$CLAUDE_SKILLS/$1" src="$SKILLS_DIR/$1" target
  if [[ -L "$dest" ]]; then
    target="$(readlink "$dest")"
    if [[ "$target" == "$src" ]]; then echo linked; else echo foreign; fi
  elif [[ -e "$dest" ]]; then
    echo real
  else
    echo unlinked
  fi
}

# A colored one-word badge for a status.
status_badge() {
  case "$1" in
    linked)   echo "${C_GREEN}●${C_RESET} linked" ;;
    foreign)  echo "${C_YELLOW}◆${C_RESET} foreign" ;;
    real)     echo "${C_BLUE}■${C_RESET} real" ;;
    unlinked) echo "${C_DIM}○ unlinked${C_RESET}" ;;
    *)        echo "$1" ;;
  esac
}

# --- interactive picker ------------------------------------------------------
# pick_skill <prompt> [only-linked]
# Prints the chosen skill name to stdout. Uses fzf when interactive; falls back
# to a numbered menu. Pass "linked" as 2nd arg to restrict to dev-linked skills.
pick_skill() {
  local prompt="${1:-select a skill}" filter="${2:-}"
  local names=() n st
  while IFS= read -r n; do
    [[ -z "$n" ]] && continue
    st="$(link_status "$n")"
    if [[ "$filter" == "linked" && "$st" != "linked" ]]; then continue; fi
    names+=("$n")
  done < <(skill_names)

  if [[ ${#names[@]} -eq 0 ]]; then
    die "no ${filter:+$filter }skills found under $SKILLS_DIR"
  fi

  # Build "name<TAB>badge" rows so the picker shows status inline.
  local rows="" pad
  for n in "${names[@]}"; do
    st="$(link_status "$n")"
    printf -v pad '%-14s' "$n"
    rows+="${n}"$'\t'"${pad}$(status_badge "$st")"$'\n'
  done

  if [[ -t 0 && -t 2 ]] && command -v fzf >/dev/null 2>&1; then
    printf '%s' "$rows" \
      | fzf --ansi --with-nth=2.. --delimiter=$'\t' \
            --height=~40% --reverse --prompt="$prompt ▸ " \
      | cut -f1
    return
  fi

  # Fallback: numbered menu on stderr, read choice from the tty.
  info "$prompt:"
  local i=1
  for n in "${names[@]}"; do
    st="$(link_status "$n")"
    printf -v pad '%-14s' "$n"
    info "  ${C_DIM}$i)${C_RESET} ${pad}$(status_badge "$st")"
    i=$((i + 1))
  done
  local choice
  printf '#? ' >&2
  read -r choice < /dev/tty || die "no selection"
  [[ "$choice" =~ ^[0-9]+$ ]] || die "not a number: $choice"
  [[ "$choice" -ge 1 && "$choice" -le ${#names[@]} ]] || die "out of range: $choice"
  echo "${names[$((choice - 1))]}"
}
