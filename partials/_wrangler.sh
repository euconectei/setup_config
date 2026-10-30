#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed wrangler; then info "wrangler ja instalado"; else step "Instalando wrangler"; npm install -g wrangler; fi
