#!/usr/bin/env bash
# List every skill in the repo with its dev-link status, aggregated across
# every AI tool's skills dir (~/.claude/skills and ~/.agents/skills).
# Usage: scripts/list.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

count=0
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  printf '  %-16s %s\n' "$name" "$(status_badge "$(agg_status "$name")")"
  count=$((count + 1))
done < <(skill_names)

[[ "$count" -eq 0 ]] && info "no skills found under $SKILLS_DIR"
echo
echo "${C_DIM}$count skills · ${C_GREEN}●${C_DIM} linked  ${C_YELLOW}◑${C_DIM} partial  ${C_YELLOW}◆${C_DIM} foreign  ${C_BLUE}■${C_DIM} real  ○ unlinked${C_RESET}"
