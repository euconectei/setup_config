#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "xcode e so macOS"; exit 0; }
if xcode-select -p >/dev/null 2>&1; then
  info "Xcode CLT ja instalado"
else
  step "Instalando Xcode Command Line Tools"
  xcode-select --install
fi
