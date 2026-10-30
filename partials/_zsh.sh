#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed zsh; then info "zsh ja instalado"; else step "Instalando zsh"; brew install zsh zsh-completions; fi
if [[ "$SHELL" != *zsh ]]; then
  step "Definindo zsh como shell padrao"
  command -v zsh | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$(command -v zsh)" "$USER"
fi
