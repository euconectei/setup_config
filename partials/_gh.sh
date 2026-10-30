#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed gh; then info "gh ja instalado"; else step "Instalando gh"; brew install gh; fi
