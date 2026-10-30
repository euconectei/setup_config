#!/bin/bash

set -euo pipefail

# ---- logging ----
step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
info() { printf '\033[1;32m  ->\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# ---- OS detection ----
detect_os() {
  case "$(uname -s)" in
    Darwin) echo mac ;;
    Linux)  echo linux ;;
    *)      echo unknown ;;
  esac
}
OS="$(detect_os)"

# ---- idempotency ----
is_installed() { command -v "$1" >/dev/null 2>&1; }

# ---- .zshrc ----
write_zshrc() {
  local line="$1"
  if [[ ! -f "$HOME/.zshrc" ]]; then touch "$HOME/.zshrc"; fi
  if ! grep -qxF "$line" "$HOME/.zshrc"; then
    echo "$line" >> "$HOME/.zshrc"
    info "adicionado ao .zshrc: $line"
  fi
}
