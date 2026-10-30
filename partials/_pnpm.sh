#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed pnpm; then info "pnpm ja instalado"; else step "Instalando pnpm"; brew install pnpm; fi
