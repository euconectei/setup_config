#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# python3 do Xcode CLT sempre existe; a checagem e pelo python do Homebrew
check()   { [[ -x "$(brew --prefix 2>/dev/null)/bin/python3" ]] && "$(brew --prefix)/bin/python3" -V >/dev/null 2>&1; }
install() { brew_install python; }
