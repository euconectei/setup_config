#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

STATUSLINE_SRC="$SETUP_HOME/config/claude-statusline.sh"
STATUSLINE_LINK="$HOME/.config/claude-code/statusline-command.sh"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

statusline_ok() {
  [[ "$(readlink "$STATUSLINE_LINK" 2>/dev/null)" == "$STATUSLINE_SRC" ]] \
    && grep -q statusline-command.sh "$CLAUDE_SETTINGS" 2>/dev/null
}

check() { has claude && claude --version >/dev/null 2>&1 && statusline_ok; }

install() {
  if ! has claude || ! claude --version >/dev/null 2>&1; then
    local tmp; tmp="$(mktemp)"
    retry curl -fsSL https://claude.ai/install.sh -o "$tmp"
    bash "$tmp"; rm -f "$tmp"
  fi

  # statusline versionada no repositorio (antes o script ficava solto e se perdeu)
  mkdir -p "$(dirname "$STATUSLINE_LINK")" "$(dirname "$CLAUDE_SETTINGS")"
  ln -sfn "$STATUSLINE_SRC" "$STATUSLINE_LINK"
  [[ -f "$CLAUDE_SETTINGS" ]] && backup_file "$CLAUDE_SETTINGS"
  /usr/bin/python3 - "$CLAUDE_SETTINGS" <<'PY'
import json, os, sys
p = sys.argv[1]
d = json.load(open(p)) if os.path.exists(p) else {}
d.setdefault("statusLine", {"type": "command", "command": "bash ~/.config/claude-code/statusline-command.sh"})
json.dump(d, open(p, "w"), indent=2)
PY
  info "statusline do Claude Code configurada"
}
