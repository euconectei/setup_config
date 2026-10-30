#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed git; then info "git ja instalado"; else step "Instalando git"; brew install git; fi
