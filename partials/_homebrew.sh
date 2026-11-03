#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

check() { has brew && brew --version >/dev/null 2>&1; }

install() {
  local tmp; tmp="$(mktemp)"
  retry curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$tmp"
  if [[ -t 0 ]]; then /bin/bash "$tmp"; else NONINTERACTIVE=1 /bin/bash "$tmp"; fi
  rm -f "$tmp"
  load_env   # deixa o brew disponivel ja nesta execucao (antes so no proximo terminal)
}
