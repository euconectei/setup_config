# Setup Config

Instalador idempotente e autocorretivo do ambiente de trabalho (foco em macOS; Linux best-effort).

## Instalacao

```bash
curl -fsSL https://raw.githubusercontent.com/euconectei/setup_config/master/install.sh | bash
```

Clona o repositorio em `~/.setup_config`, adiciona um unico bloco ao topo do `~/.zshrc`
(que carrega `shell/init.zsh`) e deixa o comando `setup` disponivel em qualquer terminal.
Um clone existente tambem funciona: `./init.sh` (ou `bin/setup`).

## Uso

```bash
setup                    # verifica e instala/repara o que falta (core + o que ja foi escolhido)
setup --select           # menu interativo (fzf; Enter direto = core)
setup --core             # so o core
setup --full             # core + opcional
setup --group <grupo>    # um grupo (base|shell|runtime|clis|cloud|ios|containers|apps|utils)
setup --only <a,b,c>     # so as ferramentas listadas (+ dependencias)
setup --full --skip a,b  # tudo menos a e b
setup --retry-failed     # tenta de novo apenas o que falhou
setup --dry-run          # mostra o plano sem instalar
setup update             # atualiza o proprio setup (git pull --ff-only)
setup doctor             # diagnostica e corrige
setup doctor --check     # so diagnostica
```

## Como funciona

- Cada ferramenta (`partials/_<id>.sh`) define `check` (instalada **e** funcional) e `install`.
  Se `check` passa, nada e feito; senao instala e verifica de novo.
- Falhas sao isoladas: uma ferramenta que falha nao interrompe as demais; dependentes sao pulados.
- Dependencias (coluna `deps` do `setup.tsv`) sao incluidas automaticamente.
- Downloads e instalacoes usam retry com intervalo progressivo; `brew update` roda no maximo 1x/dia.
- Estado, logs, lock e backups do `.zshrc`: `~/.local/state/setup_config/`.
- O terminal so carrega o ambiente (rapido); nada e instalado ao abrir o shell.

## Core

| id | os | grupo | descricao |
|----|----|-------|-----------|
| xcode | mac | base | Xcode Command Line Tools |
| homebrew | both | base | Homebrew |
| git | both | shell | Git |
| zsh | both | shell | Zsh + zsh-completions |
| oh-my-zsh | both | shell | Oh My Zsh + zsh-autosuggestions |
| editor | both | shell | $EDITOR + git core.editor |
| node | both | runtime | Node via fnm + LTS |
| pnpm | both | runtime | pnpm |
| ruby | both | runtime | Ruby via rbenv |
| python | both | runtime | Python (ultima estavel) |
| firefox | mac | apps | Firefox |
| claude | both | clis | Claude Code |
| opencode | both | clis | opencode |
| rtk | both | clis | rtk |
| gh | both | cloud | GitHub CLI |
| docker | both | containers | Docker via Colima (leve) |
| reactNative | both | ios | React Native deps |

## Opcional

| id | os | grupo | descricao |
|----|----|-------|-----------|
| vscode | both | apps | Visual Studio Code |
| vscode-ext | both | apps | Extensoes do VS Code (config/vscode-extensions.txt) |
| fonts | mac | apps | Fira Code |
| supabase | both | cloud | Supabase CLI |
| aws | both | cloud | AWS CLI |
| firebase | both | cloud | Firebase CLI |
| wrangler | both | cloud | Wrangler (Cloudflare) |
| bitbucket | both | cloud | Atlassian CLI (acli) |
| horusec | both | utils | Horusec |
| poetry | both | utils | Poetry |
| ripgrep | both | utils | ripgrep |
| jq | both | utils | jq |
| ghostty | mac | apps | Ghostty terminal |
| obsidian | mac | apps | Obsidian |
| axe | mac | ios | AXe (iOS Simulator automation) |
| mole | mac | utils | Mole (cleanup) |
| xcode-app | mac | ios | Xcode completo (App Store) |
| bitwarden | mac | apps | Bitwarden |
| bruno | mac | apps | Bruno (cliente de API) |
| tableplus | mac | apps | TablePlus (cliente de banco) |
| pritunl | mac | apps | Pritunl (VPN) |
| claude-app | mac | apps | Claude (desktop) |
| whatsapp | mac | apps | WhatsApp |
| linearmouse | mac | apps | LinearMouse (mouse, substitui Logi Options+) |
| unarchiver | mac | utils | The Unarchiver |
| amphetamine | mac | utils | Amphetamine (App Store) |
| trabalho | mac | apps | Atalho "Começar a trabalhar" (VPN, Colima, Ghostty, WhatsApp, Teams, Outlook) |

## Regras

- Sempre versoes estaveis/LTS (Node via fnm, Ruby via rbenv, Python ultima estavel, JDK 17).
- Configuracao de shell centralizada em `shell/init.zsh`, carregada por um bloco gerenciado no `~/.zshrc`.
