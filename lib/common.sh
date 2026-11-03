#!/bin/bash
# Biblioteca comum. Compativel com bash 3.2 (o /bin/bash do macOS):
# sem arrays associativos, sem mapfile, arrays vazios protegidos.

SETUP_HOME="${SETUP_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SETUP_STATE="${SETUP_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/setup_config}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

export SETUP_HOME SETUP_STATE
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1

# ---- logging ----
step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
info() { printf '\033[1;32m  ->\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; }

# ---- OS ----
detect_os() {
  case "$(uname -s)" in
    Darwin) echo mac ;;
    Linux)  echo linux ;;
    *)      echo unknown ;;
  esac
}
OS="$(detect_os)"
ARCH="$(uname -m)"

# ---- utilitarios ----
has() { command -v "$1" >/dev/null 2>&1; }
is_installed() { has "$1"; }   # compat

# retry <cmd...>: tenta ate SETUP_RETRIES vezes com intervalo progressivo (2s, 4s, 8s...)
retry() {
  local max="${SETUP_RETRIES:-3}" n=1 delay=2
  while true; do
    "$@" && return 0
    if (( n >= max )); then
      err "falhou apos $n tentativas: $*"
      return 1
    fi
    warn "falhou (tentativa $n/$max), nova tentativa em ${delay}s: $*"
    sleep "$delay"
    n=$((n + 1)); delay=$((delay * 2))
  done
}

# carrega no shell atual tudo que pode ter sido instalado (brew, fnm, rbenv, ~/.local/bin)
load_env() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [[ -x "$b" ]]; then [[ -n "${HOMEBREW_PREFIX:-}" ]] || eval "$("$b" shellenv bash)"; break; fi
  done
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
  # so inicializa uma vez por processo (evita PATH crescendo a cada chamada)
  if has fnm && [[ -z "${FNM_MULTISHELL_PATH:-}" ]]; then eval "$(fnm env --shell bash)"; fi
  if has rbenv && [[ ":$PATH:" != *":$HOME/.rbenv/shims:"* ]]; then eval "$(rbenv init - bash)"; fi
  if [[ "$OS" == mac ]] && [[ -x /usr/libexec/java_home ]] && /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
  fi
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
  export PATH
  hash -r
}

# ---- Homebrew ----
# brew update no maximo 1x a cada 24h, e so quando algo vai ser instalado
brew_update_if_stale() {
  local stamp="$SETUP_STATE/brew_update.stamp"
  mkdir -p "$SETUP_STATE"
  if [[ -f "$stamp" ]] && [[ -z "$(find "$stamp" -mmin +1440 2>/dev/null)" ]]; then return 0; fi
  step "Atualizando Homebrew (1x por dia)"
  if retry brew update --quiet; then touch "$stamp"; else warn "brew update falhou; seguindo com indices atuais"; fi
}

brew_has()      { brew list --formula "$1" >/dev/null 2>&1; }
brew_has_cask() { brew list --cask "$1" >/dev/null 2>&1; }

# brew_install <formula...>: instala so o que falta; em falha, atualiza indices e tenta de novo
brew_install() {
  local f missing=()
  for f in "$@"; do brew_has "${f##*/}" || missing+=("$f"); done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  brew_update_if_stale
  step "brew install ${missing[*]}"
  if ! retry brew install "${missing[@]}"; then
    warn "tentando recuperar: brew update forcado + nova tentativa"
    rm -f "$SETUP_STATE/brew_update.stamp"
    brew update --quiet || true
    brew install "${missing[@]}"
  fi
}

brew_cask() {
  local c missing=()
  for c in "$@"; do brew_has_cask "${c##*/}" || missing+=("$c"); done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  brew_update_if_stale
  step "brew install --cask ${missing[*]}"
  retry brew install --cask "${missing[@]}"
}

# npm_global <pacote> <comando> [scripts-permitidos]
# O npm 11+ bloqueia scripts de instalacao (allowScripts); libera so os pacotes listados.
npm_global() {
  has "$2" && return 0
  has npm || { err "npm nao encontrado (instale 'node')"; return 1; }
  local args=(install -g "$1")
  [[ -n "${3:-}" ]] && args+=("--allow-scripts=$3")
  step "npm ${args[*]}"
  retry npm "${args[@]}"
}

# ---- .zshrc ----
backup_file() {
  local f="$1" dir="$SETUP_STATE/backups"
  [[ -f "$f" ]] || return 0
  mkdir -p "$dir"
  local dest="$dir/$(basename "$f").$(date +%Y%m%d-%H%M%S)"
  [[ -f "$dest" ]] || cp -p "$f" "$dest"
}

# zshrc_block <nome> <conteudo> [top]: bloco gerenciado, substituido in-place (sem duplicar)
zshrc_block() {
  local name="$1" content="$2" where="${3:-bottom}"
  local begin="# >>> setup_config:$name >>>" end="# <<< setup_config:$name <<<"
  local block tmp
  block="$begin"$'\n'"$content"$'\n'"$end"
  touch "$ZSHRC"

  if grep -qF "$begin" "$ZSHRC"; then
    local current
    current="$(awk -v b="$begin" -v e="$end" '$0==b{p=1} p{print} $0==e{p=0}' "$ZSHRC")"
    [[ "$current" == "$block" ]] && return 0
    backup_file "$ZSHRC"
    tmp="$(mktemp)"
    # bloco via ENVIRON: o awk do macOS nao aceita quebra de linha em -v
    BLK="$block" awk -v b="$begin" -v e="$end" '
      $0==b {print ENVIRON["BLK"]; skip=1; next}
      $0==e {skip=0; next}
      !skip {print}' "$ZSHRC" > "$tmp"
    cat "$tmp" > "$ZSHRC"; rm -f "$tmp"
  else
    backup_file "$ZSHRC"
    if [[ "$where" == top ]]; then
      tmp="$(mktemp)"
      { printf '%s\n\n' "$block"; cat "$ZSHRC"; } > "$tmp"
      cat "$tmp" > "$ZSHRC"; rm -f "$tmp"
    else
      printf '\n%s\n' "$block" >> "$ZSHRC"
    fi
  fi
  info "atualizado ~/.zshrc (bloco $name)"
}

# compat com partials antigos: adiciona linha unica
write_zshrc() {
  local line="$1"
  touch "$ZSHRC"
  if ! grep -qxF "$line" "$ZSHRC"; then
    backup_file "$ZSHRC"
    echo "$line" >> "$ZSHRC"
    info "adicionado ao .zshrc: $line"
  fi
}
