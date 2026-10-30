#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "homebrew e so macOS"; exit 0; }
if is_installed brew; then
  info "Homebrew ja instalado"
else
  step "Instalando Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
step "Atualizando Homebrew"
brew update
