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
  case "$(link_status "$name" "$root")" in
    linked|foreign)
      rm "$dest"
      echo "${C_YELLOW}unlinked${C_RESET} $dest" ;;
    real)
      warn "$dest is not a symlink (real install) — leaving it alone." ;;
    unlinked)
      info "nothing to do: $dest does not exist" ;;
  esac
done
