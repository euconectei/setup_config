#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# Extensoes do VS Code (lista em config/vscode-extensions.txt)
LIST="$SETUP_HOME/config/vscode-extensions.txt"
# Linhas "!id" = extensoes que devem ficar desinstaladas.
installed() { code --list-extensions 2>/dev/null | tr "[:upper:]" "[:lower:]"; }
wanted()    { grep -vE "^[[:space:]]*(#|!|$)" "$LIST" | awk "{print tolower(\$1)}"; }
unwanted()  { grep -E "^[[:space:]]*!" "$LIST" | tr -d "! " | awk "{print tolower(\$1)}"; }
missing()   { local have; have="$(installed)"; wanted   | while read -r e; do grep -qx "$e" <<< "$have" || echo "$e"; done; }
extra()     { local have; have="$(installed)"; unwanted | while read -r e; do if grep -qx "$e" <<< "$have"; then echo "$e"; fi; done; }

check()   { has code && [[ -z "$(missing)" && -z "$(extra)" ]]; }
install() {
  local e
  for e in $(missing); do step "code --install-extension $e"; retry code --install-extension "$e" --force >/dev/null; done
  for e in $(extra);   do step "code --uninstall-extension $e"; code --uninstall-extension "$e" >/dev/null || true; done
}
