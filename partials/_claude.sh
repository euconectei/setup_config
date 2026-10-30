#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed claude; then info "claude ja instalado"; else step "Instalando Claude Code"; curl -fsSL https://claude.ai/install.sh | bash; fi
