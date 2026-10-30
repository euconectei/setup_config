#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed horusec; then info "horusec ja instalado"; else step "Instalando horusec"; curl -fsSL https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh | bash; fi
