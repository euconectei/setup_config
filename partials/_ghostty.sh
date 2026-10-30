#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "ghostty e so macOS"; exit 0; }
if brew list --cask ghostty >/dev/null 2>&1; then info "ghostty ja instalado"; else step "Instalando ghostty"; brew install --cask ghostty; fi
