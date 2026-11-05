#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# No macOS o Ghostty le este caminho por ultimo (sobrepoe ~/.config/ghostty), entao o link fica aqui.
GHOSTTY_CONFIG_SRC="$SETUP_HOME/config/ghostty.config"
GHOSTTY_CONFIG_LINK="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

ghostty_app_ok()    { brew_has_cask ghostty || [[ -d /Applications/Ghostty.app ]]; }
ghostty_config_ok() { [[ "$(readlink "$GHOSTTY_CONFIG_LINK" 2>/dev/null)" == "$GHOSTTY_CONFIG_SRC" ]]; }

check() { ghostty_app_ok && ghostty_config_ok; }

install() {
  ghostty_app_ok || brew_cask ghostty

  mkdir -p "$(dirname "$GHOSTTY_CONFIG_LINK")"
  # preserva um config local (ex.: o template gerado pelo app) antes de trocar pelo link
  [[ -L "$GHOSTTY_CONFIG_LINK" ]] || backup_file "$GHOSTTY_CONFIG_LINK"
  ln -sfn "$GHOSTTY_CONFIG_SRC" "$GHOSTTY_CONFIG_LINK"
  info "config do Ghostty linkada ao repositorio"
}
