#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed python3; then info "python3 ja instalado"; else step "Instalando Python"; brew install python; fi
