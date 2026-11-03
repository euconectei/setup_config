#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# homebrew/cask-fonts foi descontinuado: as fontes agora estao no cask principal
check()   { brew_has_cask font-fira-code || ls "$HOME"/Library/Fonts/FiraCode* >/dev/null 2>&1; }
install() { brew_cask font-fira-code; }
