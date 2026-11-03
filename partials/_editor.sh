#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# EDITOR e definido dinamicamente em shell/init.zsh; aqui so o git.
desired_editor() { if has code; then echo "code --wait"; else echo nano; fi; }
check()   { [[ "$(git config --global core.editor 2>/dev/null)" == "$(desired_editor)" ]]; }
install() { git config --global core.editor "$(desired_editor)"; info "git core.editor=$(desired_editor)"; }
