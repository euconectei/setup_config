#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# so existe na App Store (precisa estar logado na App Store)
check()   { [[ -d /Applications/Amphetamine.app ]]; }
install() { brew_install mas; mas install 937984704; }
