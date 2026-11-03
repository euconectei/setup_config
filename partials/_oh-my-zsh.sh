#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

OMZ="$HOME/.oh-my-zsh"
OMZ_CUSTOM="${ZSH_CUSTOM:-$OMZ/custom}"
AUTOSUG="$OMZ_CUSTOM/plugins/zsh-autosuggestions"

zshrc_sources_omz()  { grep -qE "^[^#]*source[[:space:]].*oh-my-zsh\.sh" "$ZSHRC" 2>/dev/null; }
# conteudo do primeiro plugins=( ... ) (aceita array em varias linhas)
plugins_line() {
  awk '/^[[:space:]]*plugins=\(/ {p=1} p {printf "%s ", $0; if ($0 ~ /\)/) exit}' "$ZSHRC" 2>/dev/null
}

check() {
  [[ -f "$OMZ/oh-my-zsh.sh" ]] && [[ -d "$AUTOSUG" ]] && zshrc_sources_omz \
    && [[ "$(plugins_line)" == *zsh-autosuggestions* ]]
}

install() {
  if [[ ! -f "$OMZ/oh-my-zsh.sh" ]]; then
    step "Instalando Oh My Zsh"
    local tmp; tmp="$(mktemp)"
    retry curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$tmp"
    # KEEP_ZSHRC: nao substituir o .zshrc existente (antes apagava o que outros passos escreveram)
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$tmp" --unattended
    rm -f "$tmp"
  fi

  # zsh-autosuggestions como plugin do Oh My Zsh (o pacote do brew nao e carregado por plugins=())
  if [[ ! -d "$AUTOSUG" ]]; then
    step "Instalando plugin zsh-autosuggestions"
    retry git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUG"
  fi

  if ! zshrc_sources_omz; then
    zshrc_block omz "export ZSH=\"\$HOME/.oh-my-zsh\"
ZSH_THEME=\"robbyrussell\"
plugins=(git zsh-autosuggestions)
source \$ZSH/oh-my-zsh.sh"
  elif [[ -z "$(plugins_line)" ]]; then
    warn "plugins=() nao encontrado no .zshrc; adicione zsh-autosuggestions manualmente"
    return 1
  elif [[ "$(plugins_line)" != *zsh-autosuggestions* ]]; then
    backup_file "$ZSHRC"
    # acrescenta o plugin preservando os que ja existem (antes a lista era sobrescrita)
    local tmp; tmp="$(mktemp)"
    awk '!done && /^[[:space:]]*plugins=\(/ {
           if ($0 ~ /\)/) sub(/\)/, " zsh-autosuggestions)"); else sub(/\(/, "(zsh-autosuggestions ")
           done=1 }
         {print}' "$ZSHRC" > "$tmp"
    cat "$tmp" > "$ZSHRC"; rm -f "$tmp"
    info "zsh-autosuggestions adicionado a plugins=()"
  fi
}
