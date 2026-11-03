#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# Extensoes do VS Code (lista em config/vscode-extensions.txt)
LIST="$SETUP_HOME/config/vscode-extensions.txt"
wanted()  { grep -vE "^[[:space:]]*(#|$)" "$LIST" | awk "{print tolower(\$1)}"; }
missing() { local have; have="$(code --list-extensions 2>/dev/null | tr "[:upper:]" "[:lower:]")"; wanted | while read -r e; do grep -qx "$e" <<< "$have" || echo "$e"; done; }

check()   { has code && [[ -z "$(missing)" ]]; }
install() {
  local e
  for e in $(missing); do step "code --install-extension $e"; retry code --install-extension "$e" --force >/dev/null; done
}
