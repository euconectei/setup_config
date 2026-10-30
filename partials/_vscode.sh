#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed code; then info "VS Code ja instalado"; exit 0; fi
if [[ "$OS" == mac ]]; then
  step "Instalando VS Code (cask)"
  brew install --cask visual-studio-code
else
  step "Instalando VS Code (apt)"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y code
fi
