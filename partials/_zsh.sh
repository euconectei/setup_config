#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

login_shell() {
  if [[ "$OS" == mac ]]; then dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk "{print \$2}"
  else getent passwd "$USER" | cut -d: -f7; fi
}
zsh_bin() { if [[ "$OS" == mac ]]; then echo /bin/zsh; else command -v zsh; fi; }

check() {
  has zsh && brew_has zsh-completions && [[ "$(login_shell)" == *zsh ]]
}

install() {
  if [[ "$OS" == mac ]]; then brew_install zsh-completions; else brew_install zsh zsh-completions; fi
  # compinit reclama de diretorios com permissao de escrita para o grupo
  chmod go-w "$(brew --prefix)/share" "$(brew --prefix)/share/zsh" 2>/dev/null || true

  if [[ "$(login_shell)" != *zsh ]]; then
    local z; z="$(zsh_bin)"
    grep -qxF "$z" /etc/shells || echo "$z" | sudo tee -a /etc/shells >/dev/null
    step "Definindo $z como shell padrao (pode pedir senha)"
    chsh -s "$z" || sudo chsh -s "$z" "$USER"
  fi
}
