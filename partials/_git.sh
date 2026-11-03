#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

check()   { has git && git --version >/dev/null 2>&1 && has git-lfs; }
install() { brew_install git git-lfs; git lfs install --skip-repo >/dev/null; }
