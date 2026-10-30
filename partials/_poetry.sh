#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed poetry; then info "poetry ja instalado"; else step "Instalando poetry"; brew install poetry; fi
