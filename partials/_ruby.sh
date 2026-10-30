#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed rbenv; then info "rbenv ja instalado"; else step "Instalando rbenv"; brew install rbenv ruby-build; fi
write_zshrc 'eval "$(rbenv init - zsh)"'
eval "$(rbenv init - zsh)"

latest="$(rbenv install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)"
if rbenv versions | grep -qF "$latest"; then
  info "Ruby $latest ja instalado"
else
  step "Instalando Ruby $latest"
  rbenv install "$latest"
fi
rbenv global "$latest"
ruby -v
