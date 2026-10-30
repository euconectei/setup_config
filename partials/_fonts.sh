#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if brew list --cask font-fira-code >/dev/null 2>&1; then
  info "Fira Code ja instalada"
else
  step "Instalando Fira Code"
  brew tap homebrew/cask-fonts
  brew install --cask font-fira-code
fi
