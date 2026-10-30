#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == linux ]] || { warn "linuxbrew e so Linux"; exit 0; }
if is_installed brew; then
  info "Homebrew ja instalado"
else
  step "Instalando Homebrew (Linux)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  write_zshrc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
step "Atualizando Homebrew"
brew update
