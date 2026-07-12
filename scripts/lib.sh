#!/usr/bin/env bash
# Shared helpers for the mimukit/skills tooling. Source this; don't execute it.
# Kept bash 3.2 safe (macOS /bin/bash) — no associative arrays, no `mapfile`.

# --- paths -------------------------------------------------------------------
_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$_lib_dir")"
SKILLS_DIR="$REPO_ROOT/skills"
# Skills are tool-agnostic: a dev link is mirrored into every AI tool's skills
# dir. `.claude/skills` (Claude Code) and `.agents/skills` (Codex, opencode,
# antigravity, …) are the two conventions we target.
CLAUDE_SKILLS="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
AGENTS_SKILLS="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
SKILL_DEST_DIRS=("$CLAUDE_SKILLS" "$AGENTS_SKILLS")

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

# Classify what's at <dest-root>/<name> (dest-root defaults to CLAUDE_SKILLS):
#   linked    — symlink pointing at our copy (a dev link we own)
#   foreign   — symlink pointing somewhere else
#   real      — a real file/dir (e.g. a skills.sh install) — do not touch
#   unlinked  — nothing there
link_status() {
  local name="$1" root="${2:-$CLAUDE_SKILLS}" src="$SKILLS_DIR/$1" dest target
  dest="$root/$name"
  if [[ -L "$dest" ]]; then
    target="$(readlink "$dest")"
    if [[ "$target" == "$src" ]]; then echo linked; else echo foreign; fi
  elif [[ -e "$dest" ]]; then
    echo real
  else
    echo unlinked
  fi
}

# Aggregate a skill's dev-link status across all SKILL_DEST_DIRS:
#   linked    — our symlink in every dest
#   unlinked  — absent from every dest
#   real      — a non-symlink install in at least one dest (don't touch)
#   partial   — present in some dests but not a clean link in all
agg_status() {
  local name="$1" root st all_linked=1 any_present=0 any_real=0
  for root in "${SKILL_DEST_DIRS[@]}"; do
    st="$(link_status "$name" "$root")"
    case "$st" in
      linked)   any_present=1 ;;
      foreign)  any_present=1; all_linked=0 ;;
      real)     any_real=1;    all_linked=0 ;;
      unlinked) all_linked=0 ;;
    esac
  done
  if [[ "$any_real" -eq 1 ]]; then echo real
  elif [[ "$all_linked" -eq 1 ]]; then echo linked
  elif [[ "$any_present" -eq 0 ]]; then echo unlinked
  else echo partial
  fi
}

# A colored one-word badge for a status.
status_badge() {
  case "$1" in
    linked)   echo "${C_GREEN}●${C_RESET} linked" ;;
    partial)  echo "${C_YELLOW}◑${C_RESET} partial" ;;
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
    st="$(agg_status "$n")"
    # "linked" filter (unlink picker): show anything with a dev link present.
    if [[ "$filter" == "linked" && "$st" != "linked" && "$st" != "partial" && "$st" != "foreign" ]]; then continue; fi
    names+=("$n")
  done < <(skill_names)

  if [[ ${#names[@]} -eq 0 ]]; then
    die "no ${filter:+$filter }skills found under $SKILLS_DIR"
  fi

  # Build "name<TAB>badge" rows so the picker shows status inline.
  local rows="" pad
  for n in "${names[@]}"; do
    st="$(agg_status "$n")"
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
    st="$(agg_status "$n")"
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
