# Setup Config

Auto-instala o ambiente de trabalho (macOS e Linux).

## Uso

```bash
./init.sh                        # menu interativo (fzf), Enter vazio = core
./init.sh --core                 # so o core
./init.sh --full                 # core + opcional
./init.sh --group <grupo>        # um grupo (base|shell|runtime|clis|cloud|ios|containers|apps|utils)
./init.sh --only <a,b,c>         # so as ferramentas listadas
./init.sh --dry-run              # lista sem instalar
```

## Core

| id | os | grupo | descricao |
|----|----|-------|-----------|
| xcode | mac | base | Xcode Command Line Tools |
| homebrew | mac | base | Homebrew |
| linuxbrew | linux | base | Homebrew (Linux) |
| git | both | shell | Git |
| zsh | both | shell | Zsh + zsh-completions |
| oh-my-zsh | both | shell | Oh My Zsh + plugins |
| editor | both | shell | $EDITOR + git core.editor |
| node | both | runtime | Node via fnm + LTS |
| pnpm | both | runtime | pnpm |
| ruby | both | runtime | Ruby via rbenv |
| python | both | runtime | Python (ultima estavel) |
| claude | both | clis | Claude Code |
| opencode | both | clis | opencode |
| rtk | both | clis | rtk |
| gh | both | cloud | GitHub CLI |
| docker | both | containers | Docker |
| reactNative | both | ios | React Native deps |

## Opcional

| id | os | grupo | descricao |
|----|----|-------|-----------|
| vscode | both | apps | Visual Studio Code |
| fonts | both | apps | Fira Code |
| supabase | both | cloud | Supabase CLI |
| aws | both | cloud | AWS CLI |
| firebase | both | cloud | Firebase CLI |
| wrangler | both | cloud | Wrangler (Cloudflare) |
| bitbucket | both | cloud | Atlassian CLI |
| horusec | both | utils | Horusec |
| poetry | both | utils | Poetry |
| ripgrep | both | utils | ripgrep |
| jq | both | utils | jq |
| ghostty | mac | apps | Ghostty terminal |
| obsidian | mac | apps | Obsidian |
| axe | mac | ios | AXe (iOS Simulator automation) |
| mole | mac | utils | Mole (cleanup) |

## Regras

- Sempre versoes estaveis/LTS (Node via fnm, Ruby via rbenv, Python ultima estavel, JDK 17).
- Todo config vai para `~/.zshrc`.
