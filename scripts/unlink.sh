#!/usr/bin/env bash
# Remove a dev symlink created by link.sh. Refuses to touch non-symlinks.
# Usage: scripts/unlink.sh [skill-name]   (no name → picker of linked skills)
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

name="${1:-}"
[[ -z "$name" ]] && name="$(pick_skill 'unlink skill' linked)"
[[ -z "$name" ]] && { info "nothing selected"; exit 0; }

for root in "${SKILL_DEST_DIRS[@]}"; do
  dest="$root/$name"
  bak="$(backup_path "$name" "$root")"
  case "$(link_status "$name" "$root")" in
    linked|foreign)
      rm "$dest"
      echo "${C_YELLOW}unlinked${C_RESET} $dest"
      if [[ -e "$bak" || -L "$bak" ]]; then
        mv "$bak" "$dest"
        echo "${C_GREEN}restored${C_RESET} $dest ${C_DIM}(from $(basename "$bak"))${C_RESET}"
      fi ;;
    real)
      warn "$dest is not a symlink (real install) — leaving it alone." ;;
    unlinked)
      if [[ -e "$bak" || -L "$bak" ]]; then
        mv "$bak" "$dest"
        echo "${C_GREEN}restored${C_RESET} $dest ${C_DIM}(from $(basename "$bak"))${C_RESET}"
      else
        info "nothing to do: $dest does not exist"
      fi ;;
  esac
done
