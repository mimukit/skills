#!/usr/bin/env bash
# Remove a dev symlink created by link.sh. Refuses to touch non-symlinks.
# Usage: scripts/unlink.sh [skill-name]   (no name → picker of linked skills)
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

name="${1:-}"
[[ -z "$name" ]] && name="$(pick_skill 'unlink skill' linked)"
[[ -z "$name" ]] && { info "nothing selected"; exit 0; }

dest="$CLAUDE_SKILLS/$name"

case "$(link_status "$name")" in
  linked|foreign)
    rm "$dest"
    echo "${C_YELLOW}unlinked${C_RESET} $dest" ;;
  real)
    die "$dest is not a symlink (real install) — leaving it alone." ;;
  unlinked)
    info "nothing to do: $dest does not exist" ;;
esac
