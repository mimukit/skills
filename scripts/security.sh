#!/usr/bin/env bash
# Heuristic security scan for each skill's SKILL.md — a local, offline stand-in
# for the scanners skills.sh runs at publish time (Gen Agent Trust Hub, Socket,
# Snyk). It cannot be byte-identical to those services, but it catches the same
# *classes* of finding so a flag surfaces here before it shows up public on the
# directory page.
#
# What it looks for, and which scanner it mirrors:
#   - autonomous shell execution        (Gen)   — skill tells the agent to run commands on its own
#   - broad / implicit tool grant       (Gen)   — no allowed-tools, so it inherits Bash/Write/etc.
#   - detection-evasion language        (Snyk)  — "evade/bypass … detector/classifier", "undetectable"
#   - network exfiltration              (Socket)— curl/wget/POST to external hosts, "send … to"
#   - secret / credential handling      (Snyk)  — reads or writes tokens, API keys, passwords
#   - destructive / injection commands  (Gen)   — rm -rf, sudo, chmod 777, curl|bash, eval of input
#
# Each finding carries a severity; a skill's tier is the max severity of its
# findings (none→Safe, low→Low, med→Med, high→High). Mirrors the skills.sh table.
#
# Usage: scripts/security.sh [skill-name ...]      (default: all skills)
# Exit status is non-zero when any skill lands at or above SECURITY_FAIL_TIER
# (default: high), so CI can gate on it.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Tier at or above which the run fails (safe|low|med|high). Default: high only.
FAIL_TIER="${SECURITY_FAIL_TIER:-high}"

# --- severity helpers (bash 3.2: no associative arrays) ----------------------
sev_rank() {  # numeric rank so we can take a max
  case "$1" in safe) echo 0 ;; low) echo 1 ;; med) echo 2 ;; high) echo 3 ;; *) echo 0 ;; esac
}
tier_badge() {
  case "$1" in
    safe) echo "${C_GREEN}Safe${C_RESET}" ;;
    low)  echo "${C_BLUE}Low Risk${C_RESET}" ;;
    med)  echo "${C_YELLOW}Med Risk${C_RESET}" ;;
    high) echo "${C_RED}High Risk${C_RESET}" ;;
    *)    echo "$1" ;;
  esac
}

worst_tier="safe"          # highest tier seen across all skills
scanned=0

# The top YAML frontmatter block (between the first two `---` lines).
frontmatter() {
  awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$1"
}

# case-insensitive, extended-regex match helpers — return 0 if the pattern hits.
hits()  { grep -qiE "$2" "$1"; }              # $1 = file path
shits() { printf '%s' "$1" | grep -qiE "$2"; } # $1 = string (e.g. the body)

scan_skill() {
  local name="$1" file="$SKILLS_DIR/$1/SKILL.md" fm tier="safe"
  local findings=()  # each entry: "sev|message"

  if [[ ! -f "$file" ]]; then
    echo "  ${C_RED}✗${C_RESET} $name — no SKILL.md"; worst_tier="high"; return
  fi
  fm="$(frontmatter "$file")"

  # Body only (strip frontmatter) so allowed-tools text itself isn't scanned as prose.
  local body; body="$(awk 'f{print} /^---[[:space:]]*$/{c++} c==2 && !f{f=1}' "$file")"

  add() { findings+=("$1|$2"); }

  # --- Gen: autonomous shell execution ---------------------------------------
  # Imperative "run/execute" near a shell command or fenced ```sh/bash block.
  if hits "$file" 'run (the )?(automated )?(check|command|script|`)' \
     || grep -qE '```(sh|bash|shell|zsh)' "$file"; then
    if hits "$file" '\b(run|execute|invoke) (it|them|this|the|these|`)' \
       || hits "$file" 'run the (automated|checks|commands) '; then
      add med "instructs the agent to run shell commands on its own (autonomous execution)"
    fi
  fi

  # --- Gen: broad / implicit tool grant --------------------------------------
  # No allowed-tools in frontmatter → the skill inherits every tool, Bash included.
  if ! printf '%s\n' "$fm" | grep -qiE '^allowed-tools:'; then
    if grep -qE '```(sh|bash|shell)' "$file" || hits "$file" '\b(git |run |command|terminal|shell)\b'; then
      add med "no allowed-tools declared, yet it uses the shell — inherits ALL tools (Bash, Write, …); scope it"
    else
      add low "no allowed-tools declared — inherits all tools; declare the minimal set it needs"
    fi
  else
    # Declared, but grants Bash alongside write access without saying why → note it.
    if printf '%s\n' "$fm" | grep -qiE '^allowed-tools:.*(bash|execute)' \
       && printf '%s\n' "$fm" | grep -qiE '^allowed-tools:.*(write|edit)'; then
      add low "grants Bash together with Write/Edit — confirm the skill genuinely needs both"
    fi
  fi

  # --- Snyk: detection-evasion language --------------------------------------
  if hits "$file" '\b(evade|evading|bypass|defeat|circumvent|fool|beat|trick)\b[^.]{0,40}\b(detect|detector|detection|classifier|scanner|filter|moderation|guardrail)' \
     || hits "$file" '\b(undetectable|avoid detection|evade detection|slip past)\b'; then
    add high "detection-evasion phrasing — reads like a tool to defeat a classifier/scanner; reframe as legitimate editing"
  fi

  # --- Socket: network exfiltration ------------------------------------------
  if shits "$body" '\b(curl|wget|fetch|http[s]?://[^ )]+)\b[^`]{0,60}\b(post|upload|send|exfil)' \
     || shits "$body" '\bsend (it|them|this|the (file|data|output|contents)) to\b'; then
    add med "moves data to an external endpoint (possible exfiltration) — confirm the destination is trusted"
  fi

  # --- Snyk: secret / credential handling ------------------------------------
  if shits "$body" '\b(read|cat|print|log|echo|exfiltrate|collect)\b[^.`]{0,40}\b(secret|token|api[_ -]?key|password|credential|\.env|private key)'; then
    add med "reads or emits secrets/credentials — ensure they are never printed, logged, or sent anywhere"
  fi

  # --- Gen: destructive / injection commands ---------------------------------
  if shits "$body" '\brm -rf\b|\bsudo \b|\bchmod 777\b|:\(\)\{|\beval \$|curl [^|]*\| *(sh|bash)|wget [^|]*\| *(sh|bash)'; then
    add high "contains a destructive or pipe-to-shell command pattern — remove or gate it behind explicit confirmation"
  fi

  # --- roll up ---------------------------------------------------------------
  local f sev msg r max=0
  for f in "${findings[@]:-}"; do
    [[ -z "$f" ]] && continue
    sev="${f%%|*}"; r="$(sev_rank "$sev")"
    [[ "$r" -gt "$max" ]] && max="$r"
  done
  case "$max" in 0) tier=safe ;; 1) tier=low ;; 2) tier=med ;; 3) tier=high ;; esac
  [[ "$(sev_rank "$tier")" -gt "$(sev_rank "$worst_tier")" ]] && worst_tier="$tier"
  scanned=$((scanned + 1))

  printf -v pad '%-14s' "$name"
  echo "  ${pad}$(tier_badge "$tier")"
  for f in "${findings[@]:-}"; do
    [[ -z "$f" ]] && continue
    sev="${f%%|*}"; msg="${f#*|}"
    echo "      $(tier_badge "$sev" | sed 's/Risk//;s/Safe/safe/') — $msg"
  done
}

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  while IFS= read -r n; do [[ -n "$n" ]] && targets+=("$n"); done < <(skill_names)
fi

echo "${C_DIM}Heuristic security scan — a local stand-in for the skills.sh scanners (Gen/Socket/Snyk).${C_RESET}"
echo
for name in "${targets[@]}"; do
  scan_skill "$name"
done
echo
echo "${C_DIM}${scanned} skill(s) scanned · worst tier: $(tier_badge "$worst_tier")${C_RESET}"

# Gate: fail when the worst tier reaches SECURITY_FAIL_TIER.
[[ "$(sev_rank "$worst_tier")" -lt "$(sev_rank "$FAIL_TIER")" ]]
