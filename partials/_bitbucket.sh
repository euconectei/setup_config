#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed atlassian; then info "atlassian ja instalado"; else step "Instalando Atlassian CLI"; brew install --cask atlassian; fi
