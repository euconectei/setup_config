#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

check()   { brew_has_cask pritunl || [[ -d "/Applications/Pritunl.app" ]]; }
install() { brew_cask pritunl; }
