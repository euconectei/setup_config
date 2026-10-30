#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "mole e so macOS"; exit 0; }
if is_installed mole; then info "mole ja instalado"; else step "Instalando mole"; brew install mole; fi
