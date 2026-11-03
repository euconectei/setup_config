#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Gera "~/Applications/Começar a trabalhar.app", que executa bin/comecar-trabalho.

APP="$HOME/Applications/Começar a trabalhar.app"
SCRIPT="$SETUP_HOME/bin/comecar-trabalho"

check() {
  [[ -d "$APP" ]] && grep -qF "$SCRIPT" "$APP/Contents/Resources/setup_config_target" 2>/dev/null
}

install() {
  mkdir -p "$HOME/Applications"
  rm -rf "$APP"
  osacompile -o "$APP" -e "do shell script quoted form of \"$SCRIPT\" & \" > /dev/null 2>&1 &\""
  echo "$SCRIPT" > "$APP/Contents/Resources/setup_config_target"
  # icone de maleta, do proprio macOS
  local icon=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarCustomizeIcon.icns
  [[ -f "$icon" ]] && cp "$icon" "$APP/Contents/Resources/applet.icns" && touch "$APP"
  # alteracoes depois do osacompile invalidam a assinatura; no Apple Silicon o app nao abriria
  codesign --force --deep -s - "$APP" >/dev/null 2>&1
  info "criado: $APP (arraste para o Dock ou adicione aos Itens de Início)"
  [[ -f "$HOME/.config/setup_config/trabalho.conf" ]] || \
    info "para conectar a VPN automaticamente, crie ~/.config/setup_config/trabalho.conf com PRITUNL_PROFILE=\"<id>\""
}
