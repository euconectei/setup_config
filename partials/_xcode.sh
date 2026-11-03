#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

check() { xcode-select -p >/dev/null 2>&1 && [[ -x "$(xcode-select -p)/usr/bin/git" ]]; }

install() {
  # 1) tentativa headless via softwareupdate (mesmo metodo usado pelo instalador do Homebrew)
  local flag=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress label
  touch "$flag"
  label="$(softwareupdate -l 2>/dev/null | sed -n "s/^[[:space:]]*\* Label: \(Command Line Tools.*\)$/\1/p" | sort -V | tail -1)"
  if [[ -n "$label" ]]; then
    step "Instalando $label (pode pedir senha)"
    sudo softwareupdate -i "$label" --verbose || true
  fi
  rm -f "$flag"
  check && return 0

  # 2) fallback: instalador grafico, aguardando a conclusao (antes o script seguia sem esperar)
  xcode-select --install >/dev/null 2>&1 || true
  step "Conclua a instalacao na janela do macOS; aguardando (ate 30 min)..."
  local i
  for i in $(seq 1 180); do
    check && return 0
    sleep 10
  done
  err "Xcode CLT nao foi instalado a tempo"
  return 1
}
