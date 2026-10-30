#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed rtk; then info "rtk ja instalado"; else step "Instalando rtk"; brew tap anomalyco/tap && brew install rtk; fi
