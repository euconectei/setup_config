#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

check()   { brew_has_cask obsidian || [[ -d /Applications/Obsidian.app ]]; }
install() { brew_cask obsidian; }
