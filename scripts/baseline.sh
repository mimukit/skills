#!/usr/bin/env bash
# diffkit's mechanical half: fetch a skill's upstream SKILL.md (from baselines.json)
# and line-diff it against the cached snapshot in .baselines/. The semantic gap
# analysis and review-marking stay in the diffkit skill; this just feeds it.
#
# Usage:
#   scripts/baseline.sh [diff] [skill]   diff live upstream vs snapshot (default)
#   scripts/baseline.sh save [skill]     refresh the snapshot to live upstream
#   scripts/baseline.sh list             list skills that have baseline entries
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

BASELINES_JSON="$REPO_ROOT/baselines.json"
SNAPSHOT_DIR="$REPO_ROOT/.baselines"
[[ -f "$BASELINES_JSON" ]] || die "no baselines.json at $BASELINES_JSON"
command -v jq >/dev/null 2>&1 || die "jq is required"
command -v curl >/dev/null 2>&1 || die "curl is required"

# Names that have at least one baseline source.
baseline_names() { jq -r 'to_entries[] | select(.value.sources | length > 0) | .key' "$BASELINES_JSON" | sort; }

pick_baseline() {
  local names=() n
  while IFS= read -r n; do [[ -n "$n" ]] && names+=("$n"); done < <(baseline_names)
  [[ ${#names[@]} -eq 0 ]] && die "no skills have baseline entries"
  if [[ -t 0 && -t 2 ]] && command -v fzf >/dev/null 2>&1; then
    printf '%s\n' "${names[@]}" | fzf --height=~40% --reverse --prompt='baseline ▸ '
  else
    printf '%s\n' "${names[@]}"
  fi
}

# Fetch a source's raw upstream to stdout; retry master if the branch 404s.
fetch_upstream() {
  local repo="$1" branch="$2" path="$3" url
  url="https://raw.githubusercontent.com/$repo/$branch/$path"
  if curl -fsSL "$url" 2>/dev/null; then return 0; fi
  if [[ "$branch" != "master" ]]; then
    url="https://raw.githubusercontent.com/$repo/master/$path"
    curl -fsSL "$url" 2>/dev/null && return 0
  fi
  return 1
}

# Iterate a skill's sources, calling `handle <name> <i> <repo> <branch> <path>`.
each_source() {
  local name="$1" handle="$2" count i repo branch path
  count="$(jq -r --arg n "$name" '.[$n].sources | length // 0' "$BASELINES_JSON")"
  [[ "$count" == "0" || -z "$count" ]] && die "skill '$name' has no baseline sources"
  i=0
  while [[ "$i" -lt "$count" ]]; do
    repo="$(jq -r --arg n "$name" --argjson i "$i" '.[$n].sources[$i].repo'   "$BASELINES_JSON")"
    branch="$(jq -r --arg n "$name" --argjson i "$i" '.[$n].sources[$i].branch // "main"' "$BASELINES_JSON")"
    path="$(jq -r --arg n "$name" --argjson i "$i" '.[$n].sources[$i].path'   "$BASELINES_JSON")"
    "$handle" "$name" "$i" "$repo" "$branch" "$path"
    i=$((i + 1))
  done
}

do_diff() {
  local name="$1" i="$2" repo="$3" branch="$4" path="$5"
  local snap="$SNAPSHOT_DIR/${name}__${i}.md" live
  echo "${C_BLUE}▸ $name [source $i]${C_RESET} $repo/$path @ $branch"
  live="$(fetch_upstream "$repo" "$branch" "$path")" || { warn "  fetch failed"; return; }
  if [[ ! -s "$snap" ]]; then
    info "  no prior snapshot — first review (run 'save' to set the watermark)"
    return
  fi
  if diff -u "$snap" <(printf '%s' "$live") >/dev/null 2>&1; then
    echo "  ${C_GREEN}up to date${C_RESET} — no upstream changes since last review"
  else
    diff -u --label "snapshot (last review)" --label "upstream (now)" \
      "$snap" <(printf '%s' "$live") || true
  fi
}

do_save() {
  local name="$1" i="$2" repo="$3" branch="$4" path="$5"
  local snap="$SNAPSHOT_DIR/${name}__${i}.md" live
  live="$(fetch_upstream "$repo" "$branch" "$path")" || { warn "fetch failed for $name[$i]"; return; }
  mkdir -p "$SNAPSHOT_DIR"
  printf '%s' "$live" > "$snap"
  echo "${C_GREEN}saved${C_RESET} snapshot $snap"
}

cmd="${1:-diff}"
case "$cmd" in
  list) baseline_names ;;
  diff|save)
    name="${2:-}"
    [[ -z "$name" ]] && name="$(pick_baseline)"
    [[ -z "$name" ]] && { info "nothing selected"; exit 0; }
    each_source "$name" "do_$cmd" ;;
  *)
    # allow `baseline.sh <skill>` as shorthand for `diff <skill>`
    name="$cmd"
    each_source "$name" do_diff ;;
esac
