#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed docker; then
  info "docker ja instalado"
elif [[ "$OS" == mac ]]; then
  step "Instalando Docker Desktop"
  brew install --cask docker
else
  step "Instalando Docker Engine"
  curl -fsSL https://get.docker.com | sh
fi
