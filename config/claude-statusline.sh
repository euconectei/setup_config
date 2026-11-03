#!/bin/bash
# Statusline do Claude Code. Recebe o estado da sessao em JSON pelo stdin.
# Instalado em ~/.config/claude-code/statusline-command.sh (link) por: setup --only claude
# Exemplo:  setup_config  master*  Opus  $0.42

input="$(cat)"
j() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }

dir="$(j .workspace.current_dir)"; [[ -z "$dir" ]] && dir="$(j .cwd)"; [[ -z "$dir" ]] && dir="$PWD"
model="$(j .model.display_name)"
cost="$(j .cost.total_cost_usd)"

c_dir=$'\033[1;36m'; c_git=$'\033[35m'; c_mod=$'\033[33m'; c_dim=$'\033[2m'; c_off=$'\033[0m'

out="${c_dir}$(basename "$dir")${c_off}"

if branch="$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)"; then
  dirty=""; [[ -n "$(git -C "$dir" status --porcelain -uno 2>/dev/null | head -1)" ]] && dirty="*"
  out+="  ${c_git}${branch}${dirty}${c_off}"
fi

[[ -n "$model" ]] && out+="  ${c_mod}${model}${c_off}"
[[ -n "$cost" ]] && out+="  ${c_dim}\$$(LC_ALL=C awk -v c="$cost" 'BEGIN{printf "%.2f", c}')${c_off}"

printf '%s' "$out"
