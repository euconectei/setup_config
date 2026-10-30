#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed jq; then info "jq ja instalado"; else step "Instalando jq"; brew install jq; fi
