#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

rbenv_ruby_ok() { has rbenv && [[ "$(rbenv version-name 2>/dev/null)" != system ]] && ruby -v >/dev/null 2>&1; }

check() { rbenv_ruby_ok; }

install() {
  # libyaml/openssl: sem eles o rbenv install falha (psych/openssl)
  brew_install rbenv ruby-build libyaml openssl@3
  load_env
  local latest
  latest="$(rbenv versions --bare 2>/dev/null | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -1 || true)"
  if [[ -z "$latest" ]]; then
    latest="$(rbenv install -l 2>/dev/null | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | tail -1 || true)"
    [[ -n "$latest" ]] || { err "nao foi possivel listar versoes do Ruby (rbenv install -l)"; return 1; }
    step "Instalando Ruby $latest (demora alguns minutos)"
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)" rbenv install --skip-existing "$latest"
  fi
  rbenv global "$latest"
  load_env
  info "$(ruby -v)"
}
