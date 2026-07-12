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
    foreign|real)
      # Anything that isn't our own dev link gets moved aside, never deleted —
      # a `real` dir is a skills.sh install; a `foreign` symlink is the link
      # skills.sh drops in ~/.claude/skills pointing at the real copy under
      # ~/.agents/skills. `mv` preserves either kind so `unlink` can restore it.
      bak="$(backup_path "$name" "$root")"
      if [[ -e "$bak" || -L "$bak" ]]; then
        warn "$dest collides with an existing install but a backup already exists at $bak — skipping to avoid clobbering it"
        continue
      fi
      info "backing up existing install: $dest -> $bak"
      mv "$dest" "$bak" ;;
  esac
  mkdir -p "$root"
  ln -s "$src" "$dest"
  echo "${C_GREEN}linked${C_RESET} $dest -> $src"
done
