#!/bin/bash
# Bootstrap: instala (ou atualiza) o setup em ~/.setup_config e executa.
#   curl -fsSL https://raw.githubusercontent.com/euconectei/setup_config/master/install.sh | bash
# Argumentos sao repassados ao setup:  ... | bash -s -- --core
set -euo pipefail

REPO="${SETUP_REPO:-https://github.com/euconectei/setup_config.git}"
DEST="${SETUP_HOME:-$HOME/.setup_config}"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# Num Mac novo, "git" e so um atalho que pede o Xcode CLT: instala e espera antes de clonar.
if [[ "$(uname -s)" == Darwin ]] && ! xcode-select -p >/dev/null 2>&1; then
  say "Instalando Xcode Command Line Tools (necessario para o git)"
  xcode-select --install >/dev/null 2>&1 || true
  say "Conclua a instalacao na janela do macOS; aguardando..."
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi

if [[ -d "$DEST/.git" ]]; then
  say "Atualizando $DEST"
  git -C "$DEST" pull --ff-only || say "nao foi possivel atualizar (alteracoes locais?); usando a versao atual"
else
  say "Clonando setup em $DEST"
  git clone --depth 1 "$REPO" "$DEST"
fi

chmod +x "$DEST/bin/setup"

# Quando executado via "curl | bash", o stdin e o pipe: devolve o terminal para os prompts (sudo, fzf).
if [[ -r /dev/tty ]] && { : < /dev/tty; } 2>/dev/null; then
  exec "$DEST/bin/setup" "$@" < /dev/tty
else
  exec "$DEST/bin/setup" "$@"
fi
