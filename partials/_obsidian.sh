#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "obsidian e so macOS"; exit 0; }
if brew list --cask obsidian >/dev/null 2>&1; then info "obsidian ja instalado"; else step "Instalando obsidian"; brew install --cask obsidian; fi
