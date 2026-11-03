#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# Xcode completo (App Store, ~40 GB). Necessario para builds iOS.
check() {
  [[ -d /Applications/Xcode.app ]] && [[ "$(xcode-select -p 2>/dev/null)" == /Applications/Xcode.app/* ]] \
    && xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1
}
install() {
  if [[ ! -d /Applications/Xcode.app ]]; then
    brew_install mas
    step "Baixando Xcode pela App Store (demora; precisa estar logado na App Store)"
    mas install 497799835
  fi
  step "Configurando Xcode (pede senha)"
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept
  sudo xcodebuild -runFirstLaunch
}
