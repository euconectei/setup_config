# Redesign do setup_config — Spec de Design

Data: 2026-10-30
Status: aguardando revisão do usuário

## 1. Objetivo

Modernizar o `setup_config` (auto-instalação da máquina de trabalho). O projeto
estava desatualizado (scripts mortos, comandos obsoletos, ferramentas
descontinuadas). Após levantamento da máquina e dos projetos em `Projects/`,
definimos o que entra, o que sai e o split core/opcional.

## 2. Regras e decisões

1. **Sempre versões estáveis/LTS** em qualquer runtime (Node, Python, Ruby, JDK).
2. **Suporte a macOS e Linux**, ambos mantidos no `init.sh`.
3. **Node** via `fnm` (mais performático que `nvm`; sem travar o shell).
4. **Ruby** via `rbenv` (o system Ruby do macOS é deprecated; o CocoaPods já roda
   via rbenv na máquina).
5. **Python** na última versão estável (`brew install python`).
6. **JDK 17** (Zulu/LTS) para React Native — RN não suporta JDK 25.
7. **Android SDK CLI-only** (sem Android Studio): `android-commandlinetools` +
   `sdkmanager` para platform-tools, emulator, system-images e ndk.
8. **Split core/opcional** definido num manifest (`setup.tsv`), não em arrays hardcoded.
9. **Tudo vai pro `.zshrc`** (shell padrão é Zsh; `.bashrc` cai em desuso).
10. **Manifest `setup.tsv`** como fonte única de verdade (id, os, tier, group, descrição).
11. **Seleção flexível**: menu interativo (`fzf`) + flags `--core`/`--full`/`--group`/`--only`/`--dry-run`.

## 3. Estrutura de arquivos

```
setup_config/
├── init.sh          # orquestra: lê setup.tsv, resolve seleção, executa partials
├── setup.tsv        # manifest = fonte única de verdade
├── lib/
│   └── common.sh    # helpers: log(), is_installed(), install(), detect_os()
├── partials/
│   └── _*.sh        # um por ferramenta, idempotente (fonte: lib/common.sh)
└── README.md        # gerado a partir do setup.tsv (sem duplicação)
```

### Manifest (`setup.tsv`)

Colunas (separadas por whitespace; `#` = comentário): `id` · `os` · `tier` · `group` · `descricao`

```
# id         os      tier      group       descricao
node         both    core      runtime     Node via fnm + LTS
gh           both    core      cloud       GitHub CLI
reactNative  mac     core      ios         watchman, cocoapods, zulu17, android-sdk, eas-cli
ghostty      mac     optional  apps        Ghostty terminal
axe          mac     optional  ios         AXe (iOS Simulator automation)
```

- `os`: `both` | `mac` | `linux`
- `tier`: `core` | `optional`
- `group`: `base` · `shell` · `runtime` · `clis` · `cloud` · `ios` · `containers` · `apps` · `utils`

Adicionar/remover ferramenta = editar uma linha no `setup.tsv` + criar/remover o
`partials/_*.sh` correspondente. O `README.md` é gerado a partir do manifest.

### Scripts core

| Arquivo | O que instala | OS |
|---------|---------------|----|
| `_xcode.sh` | Xcode Command Line Tools (`xcode-select --install`) | macOS |
| `_homebrew.sh` | Homebrew (install script `install/HEAD`) + `brew update` | macOS |
| `_linuxbrew.sh` | Homebrew no Linux + PATH (`brew shellenv`) | Linux |
| `_git.sh` | Git (`brew install git`) | ambos |
| `_zsh.sh` | Zsh + zsh-completions + shell padrão (`chsh`) | ambos |
| `_oh-my-zsh.sh` | Oh My Zsh (URL `ohmyzsh/ohmyzsh`) + plugins git/autosuggestions | ambos |
| `_editor.sh` | `$EDITOR` (prefere `code --wait`, senão `nano`) + git `core.editor` | ambos |
| `_node.sh` | `fnm` + `fnm install --lts` + `fnm default lts` | ambos |
| `_pnpm.sh` | pnpm (`brew install pnpm`) | ambos |
| `_ruby.sh` | `rbenv` + `ruby-build` + Ruby (última estável, ex. 3.4.x) + `rbenv global` | ambos |
| `_python.sh` | Python (`brew install python`, última estável) | ambos |
| `_gh.sh` | GitHub CLI (`brew install gh`) | ambos |
| `_claude.sh` | Claude Code (install script nativo `claude.ai/install.sh`) | ambos |
| `_opencode.sh` | opencode (`brew install opencode`, tap `anomalyco/tap`) | ambos |
| `_rtk.sh` | rtk (`brew install rtk`, tap `anomalyco/tap`) | ambos |
| `_docker.sh` | Docker Desktop (cask) / Docker Engine (Linux) | ambos |
| `_reactNative.sh` | watchman, cocoapods (via rbenv), zulu@17, android-commandlinetools + SDK, eas-cli | macOS-primário |

### Scripts opcionais (`--full`)

| Arquivo | O que instala | OS |
|---------|---------------|----|
| `_vscode.sh` | VS Code (mac: cask / Linux: apt) | segmentado |
| `_fonts.sh` | Fira Code (cask) | ambos |
| `_supabase.sh` | Supabase CLI (`brew install supabase`) | ambos |
| `_aws.sh` | AWS CLI (`brew install awscli`) | ambos |
| `_horusec.sh` | Horusec (install script oficial da ZupIT) | ambos |
| `_poetry.sh` | Poetry (`brew install poetry`) | ambos |
| `_ripgrep.sh` | ripgrep (`brew install ripgrep`) | ambos |
| `_jq.sh` | jq (`brew install jq`) | ambos |
| `_firebase.sh` | Firebase CLI (`npm install -g firebase-tools`) | ambos |
| `_wrangler.sh` | Wrangler/Cloudflare (`npm install -g wrangler`) | ambos |
| `_bitbucket.sh` | Atlassian CLI (cask `atlassian`) | ambos |
| `_ghostty.sh` | Ghostty (cask) | macOS |
| `_obsidian.sh` | Obsidian (cask) | macOS |
| `_axe.sh` | AXe (iOS Simulator automation, tap `cameroncooke/axe`) | macOS |
| `_mole.sh` | Mole (limpeza do Mac, `brew install mole`) | macOS |

### Scripts removidos

`_ruby.sh` (apt antigo) · `_jekyll.sh` · `_apache.sh` · `_aula.sh` ·
`_atom-pdf.sh` · `_hide-icons.sh` · `_mongodb.sh`

Ferramentas que saem da lista (instaladas mas sem uso nos projetos): `rust`,
`deno`, `ffmpeg`, `graphviz`, `mongodb`, `kiro-cli`, `agy`.

## 4. Fluxo do `init.sh` (seleção)

O `init.sh` lê o `setup.tsv` e filtra por `os` + seleção do usuário. Modos:

```bash
./init.sh                        # menu interativo (fzf), core já marcado
./init.sh --core                 # só core
./init.sh --full                 # core + opcional
./init.sh --group ios            # instala um grupo inteiro
./init.sh --only node,gh,docker  # cherry-pick de ferramentas
./init.sh --dry-run              # só lista o que seria instalado
```

- Sem flag e sem TTY → assume `--core`.
- `fzf` é a única dependência do modo interativo; se ausente, cai pro `--core`.
- Cada `_*.sh` é idempotente (checa `is_installed` antes de instalar).
- `reactNative` no Linux roda Android-only (sem CocoaPods).

## 5. Android SDK CLI-only (substitui Android Studio)

```bash
brew install --cask zulu@17
brew install --cask android-commandlinetools
sdkmanager --install \
  "platform-tools" \
  "platforms;android-35" \
  "build-tools;35.0.0" \
  "emulator" \
  "ndk;27.1.12297006" \
  "system-images;android-35;google_apis;arm64-v8a"
yes | sdkmanager --licenses
```

- `platform-tools` = adb/fastboot (celular físico).
- `emulator` + `system-images` = emuladores.
- `ndk` = exigido pelo RN novo.
- `ANDROID_HOME` e PATH exportados no `.zshrc`.

## 6. Padronização de shell

Todo config (aliases, `ANDROID_HOME`, `fnm env`, `rbenv init`, `$EDITOR`) escreve
exclusivamente no `~/.zshrc`. Nada mais vai pro `.bashrc`.

## 7. Fora de escopo (manual)

- Android Studio IDE (substituído por SDK CLI-only).
- Login/config inicial de ferramentas (gh auth, aws configure, etc.).
- Sincronização de extensões do VS Code (avaliar depois).

## 8. Histórico

| Data | O que mudou |
|------|-------------|
| 2026-10-30 | Criação da spec (redesign completo do setup) |
