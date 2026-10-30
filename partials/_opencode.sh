#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed opencode; then info "opencode ja instalado"; else step "Instalando opencode"; brew tap anomalyco/tap && brew install opencode; fi
