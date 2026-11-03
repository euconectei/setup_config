#!/bin/bash
# Claude Code statusline, shared by every profile (~/.claude-pessoal, ~/.claude-trabalho, ~/.claude).
# Installed as ~/.config/claude-code/statusline-command.sh (symlink) by: setup --only claude
# Spec: private notes (Claude Code profiles and statusline).
#
#  PESSOAL  ➜ setup_config git:(master) ✗  Opus  ctx 42%  5h 18% · 7d 63%
#
# - profile badge from $CLAUDE_CONFIG_DIR: .claude-pessoal -> PESSOAL (cyan),
#   .claude-trabalho / .claude-profissional -> TRABALHO (yellow), plain ~/.claude -> no badge
# - prompt mimics the Oh My Zsh "robbyrussell" theme
# - last input is kept in ~/.cache/claude-statusline-last.json to inspect available fields

input="$(cat)"
mkdir -p "$HOME/.cache" && printf '%s' "$input" > "$HOME/.cache/claude-statusline-last.json" 2>/dev/null

j() { jq -r "($1) // empty" <<<"$input" 2>/dev/null; }
# integer percent; accepts 0-100 or a 0-1 fraction (e.g. 0.42)
pct() { LC_ALL=C awk -v s="$1" 'BEGIN{ v=s+0; if (v>0 && v<=1 && index(s,".")) v*=100; printf "%d", v+0.5 }'; }

ESC=$'\033'
reset="${ESC}[0m"; bold="${ESC}[1m"
green="${ESC}[32m"; cyan="${ESC}[36m"; blue="${ESC}[34m"; red="${ESC}[31m"; yellow="${ESC}[33m"; dim="${ESC}[2m"
bg_cyan="${ESC}[46;30m"; bg_yellow="${ESC}[43;30m"

out=""

# profile badge
case "$(basename "${CLAUDE_CONFIG_DIR:-}")" in
  .claude-pessoal)                       out+="${bg_cyan}${bold} PESSOAL ${reset} " ;;
  .claude-trabalho|.claude-profissional) out+="${bg_yellow}${bold} TRABALHO ${reset} " ;;
esac

# robbyrussell: ➜ dir git:(branch) ✗
dir="$(j '.workspace.current_dir // .cwd')"; [[ -z "$dir" ]] && dir="$PWD"
out+="${bold}${green}➜${reset} ${cyan}$(basename "$dir")${reset}"
if branch="$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)"; then
  out+=" ${bold}${blue}git:(${red}${branch}${blue})${reset}"
  [[ -n "$(git -C "$dir" status --porcelain 2>/dev/null | head -1)" ]] && out+=" ${yellow}✗${reset}"
fi

# model
model="$(j '.model.display_name')"
[[ -n "$model" ]] && out+="  ${dim}${model}${reset}"

# context used (%)
ctx="$(j '.context_window.used_percentage')"
if [[ -z "$ctx" ]]; then
  used="$(j '.context_window.current_usage | if type=="object" then ((.input_tokens//0)+(.cache_creation_input_tokens//0)+(.cache_read_input_tokens//0)) else . end')"
  size="$(j '.context_window.context_window_size')"
  [[ -n "$used" && -n "$size" && "$size" != 0 ]] && ctx="$(LC_ALL=C awk -v u="$used" -v s="$size" 'BEGIN{printf "%d", u*100/s + 0.5}')"
fi
[[ -n "$ctx" ]] && out+="  ctx $(pct "$ctx")%"

# rate limits 5h / 7d (%)
r5="$(j '.rate_limits.five_hour.used_percentage // .rate_limits.five_hour.utilization')"
r7="$(j '.rate_limits.seven_day.used_percentage // .rate_limits.seven_day.utilization')"
if [[ -n "$r5" || -n "$r7" ]]; then
  out+="  ${dim}"
  [[ -n "$r5" ]] && out+="5h $(pct "$r5")%"
  [[ -n "$r5" && -n "$r7" ]] && out+=" · "
  [[ -n "$r7" ]] && out+="7d $(pct "$r7")%"
  out+="${reset}"
fi

printf '%s' "$out"
