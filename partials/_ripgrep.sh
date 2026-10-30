#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed rg; then info "ripgrep ja instalado"; else step "Instalando ripgrep"; brew install ripgrep; fi
