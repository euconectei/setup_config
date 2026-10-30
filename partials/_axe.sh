#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "axe e so macOS"; exit 0; }
if brew list axe >/dev/null 2>&1; then info "axe ja instalado"; else step "Instalando AXe"; brew tap cameroncooke/axe && brew install axe; fi
