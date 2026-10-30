#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed code; then EDITOR_CMD="code --wait"; else EDITOR_CMD="nano"; fi
step "Configurando EDITOR=$EDITOR_CMD"
write_zshrc "export EDITOR='$EDITOR_CMD'"
git config --global core.editor "$EDITOR_CMD"
