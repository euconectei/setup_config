#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

check() {
  has fnm && has node && node -v >/dev/null 2>&1 && fnm list 2>/dev/null | grep -q default
}

install() {
  brew_install fnm
  load_env
  if ! fnm list 2>/dev/null | grep -q lts-latest; then
    step "Instalando Node LTS"
    retry fnm install --lts
  fi
  fnm default lts-latest
  load_env
  info "node $(node -v)"
}
