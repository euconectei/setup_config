#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed firebase; then info "firebase ja instalado"; else step "Instalando firebase-tools"; npm install -g firebase-tools; fi
