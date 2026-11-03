#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.
# Bitwarden desktop + CLI (bw), usada por outros itens para buscar segredos.

check()   { { brew_has_cask bitwarden || [[ -d "/Applications/Bitwarden.app" ]]; } && has bw; }
install() {
  brew_has_cask bitwarden || [[ -d "/Applications/Bitwarden.app" ]] || brew_cask bitwarden
  has bw || brew_install bitwarden-cli
}
