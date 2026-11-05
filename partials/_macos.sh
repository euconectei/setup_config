#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"

# dominio|chave|tipo|valor  (tipo = bool|int|float|string)
macos_settings() {
  cat <<EOF
NSGlobalDomain|AppleShowAllExtensions|bool|true
com.apple.finder|ShowPathbar|bool|true
com.apple.finder|ShowStatusBar|bool|true
com.apple.finder|FXPreferredViewStyle|string|Nlsv
com.apple.finder|FXDefaultSearchScope|string|SCcf
com.apple.finder|_FXSortFoldersFirst|bool|true
com.apple.desktopservices|DSDontWriteNetworkStores|bool|true
com.apple.desktopservices|DSDontWriteUSBStores|bool|true
NSGlobalDomain|KeyRepeat|int|2
NSGlobalDomain|InitialKeyRepeat|int|15
NSGlobalDomain|NSAutomaticQuoteSubstitutionEnabled|bool|false
NSGlobalDomain|NSAutomaticDashSubstitutionEnabled|bool|false
com.apple.dock|autohide|bool|true
com.apple.dock|show-recents|bool|false
com.apple.dock|mru-spaces|bool|false
com.apple.dock|magnification|bool|true
com.apple.dock|largesize|float|72
com.apple.AppleMultitouchTrackpad|Clicking|bool|true
com.apple.driver.AppleBluetoothMultitouch.trackpad|Clicking|bool|true
NSGlobalDomain|com.apple.mouse.tapBehavior|int|1
com.apple.screencapture|location|string|$SCREENSHOTS_DIR
com.apple.screencapture|disable-shadow|bool|true
EOF
}

# valor como o `defaults read` devolve (bool vira 1/0)
expected_value() {
  case "$1:$2" in
    bool:true)  echo 1 ;;
    bool:false) echo 0 ;;
    *)          echo "$2" ;;
  esac
}

check() {
  [[ "$OS" == mac ]] || return 1
  local domain key type value
  while IFS='|' read -r domain key type value; do
    [[ "$(defaults read "$domain" "$key" 2>/dev/null)" == "$(expected_value "$type" "$value")" ]] || return 1
  done < <(macos_settings)
}

install() {
  [[ "$OS" == mac ]] || { warn "preferencias do macOS: so no macOS"; return 0; }
  mkdir -p "$SCREENSHOTS_DIR"

  local domain key type value
  while IFS='|' read -r domain key type value; do
    defaults write "$domain" "$key" "-$type" "$value"
  done < <(macos_settings)
  # tocar para clicar tambem na tela de login / host atual
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  killall Finder Dock SystemUIServer >/dev/null 2>&1 || true
  info "preferencias do macOS aplicadas (teclado e trackpad valem apos sair e entrar na sessao)"
}
