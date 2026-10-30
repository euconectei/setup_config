#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed supabase; then info "supabase ja instalado"; else step "Instalando supabase"; brew install supabase; fi
