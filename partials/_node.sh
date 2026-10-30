#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed fnm; then info "fnm ja instalado"; else step "Instalando fnm"; brew install fnm; fi
write_zshrc 'eval "$(fnm env --use-on-cd)"'
eval "$(fnm env --use-on-cd)"
step "Instalando Node LTS"
fnm install --lts
fnm default lts
node -v
