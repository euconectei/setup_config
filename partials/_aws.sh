#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed aws; then info "aws ja instalado"; else step "Instalando awscli"; brew install awscli; fi
