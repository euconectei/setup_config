#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  info "Oh My Zsh ja instalado"
else
  step "Instalando Oh My Zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if ! is_installed zsh-autosuggestions; then
  step "Instalando zsh-autosuggestions"
  brew install zsh-autosuggestions
fi

if grep -q '^plugins=' "$HOME/.zshrc" 2>/dev/null; then
  sed -i.bak 's/^plugins=.*/plugins=(git zsh-autosuggestions)/' "$HOME/.zshrc"
else
  write_zshrc 'plugins=(git zsh-autosuggestions)'
fi
