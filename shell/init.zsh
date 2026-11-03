# Carregado pelo ~/.zshrc (bloco "setup_config:init", no topo do arquivo).
# Apenas configura o ambiente; NAO instala nada (para nao deixar o terminal lento).
# Para manutencao, rode: setup

: "${SETUP_HOME:=$HOME/.setup_config}"

# Homebrew
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -x "$_b" ]] && { eval "$("$_b" shellenv zsh)"; break; }
  done
  unset _b
fi

# binarios do usuario (claude, etc.) e o comando setup
typeset -U path
path=("$SETUP_HOME/bin" "$HOME/.local/bin" $path)

# completions do brew (precisa vir antes do compinit do Oh My Zsh)
[[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/share/zsh-completions" ]] && \
  fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)

# runtimes
(( $+commands[fnm] ))   && eval "$(fnm env --use-on-cd --shell zsh)"
(( $+commands[rbenv] )) && eval "$(rbenv init - zsh)"

# Java / Android (React Native)
if [[ -x /usr/libexec/java_home ]] && /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
fi
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
[[ -d "$ANDROID_HOME" ]] && path+=("$ANDROID_HOME/emulator" "$ANDROID_HOME/platform-tools")

# editor
if [[ -z "$EDITOR" ]]; then
  if (( $+commands[code] )); then export EDITOR="code --wait"; else export EDITOR="nano"; fi
fi

# pnpm (binarios de "pnpm add -g")
export PNPM_HOME="$HOME/Library/pnpm"
path=("$PNPM_HOME" $path)

# perfis separados do Claude Code
alias claude-pessoal='CLAUDE_CONFIG_DIR=~/.claude-pessoal claude'
alias claude-trabalho='CLAUDE_CONFIG_DIR=~/.claude-trabalho claude'
