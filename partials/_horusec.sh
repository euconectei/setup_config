#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

check()   { has horusec; }
install() {
  local tmp; tmp="$(mktemp)"
  retry curl -fsSL https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh -o "$tmp"
  bash "$tmp" latest; rm -f "$tmp"
}
