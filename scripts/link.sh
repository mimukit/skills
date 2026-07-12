#!/usr/bin/env bash
# Symlink a skill from this repo into every AI tool's skills dir
# (~/.claude/skills and ~/.agents/skills) for live, save-and-test dev.
# Usage: scripts/link.sh [skill-name]   (no name → interactive picker)
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

name="${1:-}"
[[ -z "$name" ]] && name="$(pick_skill 'link skill')"
[[ -z "$name" ]] && { info "nothing selected"; exit 0; }

skill_exists "$name" || die "no skill at $SKILLS_DIR/$name"

src="$SKILLS_DIR/$name"

for root in "${SKILL_DEST_DIRS[@]}"; do
  dest="$root/$name"
  case "$(link_status "$name" "$root")" in
    linked)
      info "already linked: $dest -> $src"
      continue ;;
    foreign)
      info "replacing symlink at $dest (was -> $(readlink "$dest"))"
      rm "$dest" ;;
    real)
      warn "$dest exists and is not a symlink (likely a real install) — skipping"
      continue ;;
  esac
  mkdir -p "$root"
  ln -s "$src" "$dest"
  echo "${C_GREEN}linked${C_RESET} $dest -> $src"
done
