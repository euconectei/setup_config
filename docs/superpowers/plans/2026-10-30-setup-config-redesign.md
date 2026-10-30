# Setup Config Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernizar o `setup_config` — remover scripts obsoletos, adicionar ferramentas atuais (LTS/estável) e reestruturar a seleção via manifest `setup.tsv`.

**Architecture:** Um manifest TSV (`setup.tsv`) é a fonte única de verdade (id, os, tier, group, descricao). O `init.sh` lê o manifest, resolve a seleção (menu `fzf` ou flags `--core`/`--full`/`--group`/`--only`/`--dry-run`) e executa os partials idempotentes em `partials/`, que compartilham helpers em `lib/common.sh`.

**Tech Stack:** Bash 3+ (macOS), Homebrew, fnm, rbenv, sdkmanager, fzf (opcional).

**Spec:** `docs/superpowers/specs/2026-10-30-setup-config-design.md`

## Global Constraints

- Código e mensagens de commit em inglês; documentação e strings de UI em pt-br.
- Runtime sempre estável/LTS (Node LTS via fnm, Ruby estável via rbenv, Python última estável, JDK 17).
- Todo config de shell escreve **exclusivamente** em `~/.zshrc` (nada em `~/.bashrc`).
- Cada `partials/_*.sh` é idempotente (checa `is_installed`/`brew list` antes de instalar).
- Suporte a macOS e Linux (`os` no manifest = `both` | `mac` | `linux`).
- Nomes de partial: arquivo `partials/_<id>.sh` deve casar 1:1 com o `id` do `setup.tsv`.

---

### Task 1: Scaffolding — `lib/common.sh` + `setup.tsv`

**Files:**
- Create: `lib/common.sh`
- Create: `setup.tsv`

**Interfaces:**
- Produces: `lib/common.sh` exporta `OS` (mac|linux|unknown), funções `step()`, `info()`, `warn()`, `is_installed()`, `detect_os()`, `write_zshrc()`. `setup.tsv` define os 32 ids consumidos pelo `init.sh` e pelos partials.

- [ ] **Step 1: Create `lib/common.sh`**

```bash
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
```

- [ ] **Step 2: Create `setup.tsv`**

```
# id          os      tier      group       descricao
xcode         mac     core      base        Xcode Command Line Tools
homebrew      mac     core      base        Homebrew
linuxbrew     linux   core      base        Homebrew (Linux)
git           both    core      shell       Git
zsh           both    core      shell       Zsh + zsh-completions
oh-my-zsh     both    core      shell       Oh My Zsh + plugins
editor        both    core      shell       $EDITOR + git core.editor
node          both    core      runtime     Node via fnm + LTS
pnpm          both    core      runtime     pnpm
ruby          both    core      runtime     Ruby via rbenv
python        both    core      runtime     Python (ultima estavel)
claude        both    core      clis        Claude Code
opencode      both    core      clis        opencode
rtk           both    core      clis        rtk
gh            both    core      cloud       GitHub CLI
docker        both    core      containers  Docker
reactNative   both    core      ios         React Native deps
vscode        both    optional  apps        Visual Studio Code
fonts         both    optional  apps        Fira Code
supabase      both    optional  cloud       Supabase CLI
aws           both    optional  cloud       AWS CLI
firebase      both    optional  cloud       Firebase CLI
wrangler      both    optional  cloud       Wrangler (Cloudflare)
bitbucket     both    optional  cloud       Atlassian CLI
horusec       both    optional  utils       Horusec
poetry        both    optional  utils       Poetry
ripgrep       both    optional  utils       ripgrep
jq            both    optional  utils       jq
ghostty       mac     optional  apps        Ghostty terminal
obsidian      mac     optional  apps        Obsidian
axe           mac     optional  ios         AXe (iOS Simulator automation)
mole          mac     optional  utils       Mole (cleanup)
```

- [ ] **Step 3: Verify syntax + manifest format**

Run: `bash -n lib/common.sh`
Expected: exit 0 (sem saída).

Run: `awk '!/^#/ && NF<5 {print NR": "$0; bad=1} END{exit bad}' setup.tsv`
Expected: exit 0 (toda linha tem pelo menos 5 colunas: id os tier group descricao).

- [ ] **Step 4: Commit**

```bash
git add lib/common.sh setup.tsv
git commit -m "feat: add manifest and shared shell helpers"
```

---

### Task 2: `init.sh` + test harness

**Files:**
- Create: `tests/run.sh`
- Rewrite: `init.sh`

**Interfaces:**
- Consumes: `lib/common.sh` (`OS`, `step`, `info`, `warn`, `is_installed`), `setup.tsv`.
- Produces: `init.sh` com flags `--core` `--full` `--group <g>` `--only <a,b>` `--dry-run` `--help`; modo interativo via `fzf` (fallback `--core`). `--dry-run` imprime ids selecionados, um por linha.

- [ ] **Step 1: Write the failing test harness `tests/run.sh`**

```bash
#!/bin/bash
set -uo pipefail

cd "$(dirname "$0")/.."
fail=0

ok()   { echo "ok  - $1"; }
bad()  { echo "FAIL- $1"; fail=1; }

# 1) syntax check em todos os scripts
for f in init.sh lib/*.sh partials/*.sh; do
  [[ -f "$f" ]] || continue
  if bash -n "$f" 2>/dev/null; then ok "bash -n $f"; else bad "bash -n $f"; fi
done

# 2) selecao --dry-run
out=$(./init.sh --dry-run --only node 2>/dev/null || true)
if grep -qx 'node' <<<"$out" && ! grep -qx 'ghostty' <<<"$out"; then
  ok "--only node seleciona node e exclui ghostty"
else
  bad "--only node"; echo "$out"
fi

out=$(./init.sh --dry-run --core 2>/dev/null || true)
if grep -qx 'node' <<<"$out" && ! grep -qx 'ghostty' <<<"$out"; then
  ok "--core inclui node e exclui opcional ghostty"
else
  bad "--core"; echo "$out"
fi

out=$(./init.sh --dry-run --full 2>/dev/null || true)
if grep -qx 'ghostty' <<<"$out"; then
  ok "--full inclui opcional ghostty (mac)"
else
  bad "--full"; echo "$out"
fi

exit $fail
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run.sh`
Expected: FAIL — `./init.sh --dry-run` não existe ainda (init.sh antigo não tem a flag).

- [ ] **Step 3: Rewrite `init.sh`**

```bash
#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/setup.tsv"
PARTIALS_DIR="$SCRIPT_DIR/partials"

source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Uso: ./init.sh [opcoes]

  (sem opcao)        menu interativo (fzf), Enter vazio = core
  --core             instala so o core
  --full             instala core + opcional
  --group <grupo>    instala um grupo (base|shell|runtime|clis|cloud|ios|containers|apps|utils)
  --only <a,b,c>     instala so as ferramentas listadas
  --dry-run          lista o que seria instalado, sem instalar

EOF
}

MODE="interactive"
GROUPS=()
ONLY=()
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --core)   MODE=core ;;
    --full)   MODE=full ;;
    --group)  MODE=group; GROUPS+=("$2"); shift ;;
    --only)   MODE=only; IFS=',' read -r -a ONLY <<< "$2"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opcao desconhecida: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# ---- load manifest ----
IDS=(); OSES=(); TIERS=(); GRPS=(); DESCS=()
while read -r id os tier grp desc; do
  [[ "$id" =~ ^# ]] && continue
  [[ -z "$id" ]] && continue
  IDS+=("$id"); OSES+=("$os"); TIERS+=("$tier"); GRPS+=("$grp"); DESCS+=("$desc")
done < "$MANIFEST"

# ---- resolve interactive ----
if [[ "$MODE" == "interactive" ]]; then
  if [[ ! -t 0 ]]; then
    MODE=core
  elif ! is_installed fzf; then
    warn "fzf nao encontrado; assumindo --core"
    MODE=core
  else
    opts=()
    for i in "${!IDS[@]}"; do
      [[ "${OSES[$i]}" != both && "${OSES[$i]}" != "$OS" ]] && continue
      tag=$([[ "${TIERS[$i]}" == core ]] && echo "[core]" || echo "[opc ]")
      opts+=("$tag ${IDS[$i]}  ${DESCS[$i]}")
    done
    chosen=$(printf '%s\n' "${opts[@]}" | fzf --multi --reverse --prompt "Selecione (Enter vazio = core) > ")
    if [[ -z "$chosen" ]]; then
      MODE=core
    else
      ONLY=()
      while IFS= read -r line; do ONLY+=("${line##*  }"); done <<< "$chosen"
      MODE=only
    fi
  fi
fi

# ---- build selection ----
selected=()
for i in "${!IDS[@]}"; do
  id="${IDS[$i]}"; os="${OSES[$i]}"; tier="${TIERS[$i]}"; grp="${GRPS[$i]}"
  [[ "$os" != both && "$os" != "$OS" ]] && continue

  case "$MODE" in
    core)
      [[ "$tier" == core ]] && selected+=("$id") ;;
    full)
      selected+=("$id") ;;
    group)
      for g in "${GROUPS[@]}"; do [[ "$grp" == "$g" ]] && selected+=("$id"); done ;;
    only)
      for o in "${ONLY[@]}"; do [[ "$id" == "$o" ]] && selected+=("$id"); done ;;
  esac
done

if [[ ${#selected[@]} -eq 0 ]]; then
  warn "Nenhuma ferramenta selecionada."
  exit 1
fi

step "Selecionado (${#selected[@]}):"
printf '  %s\n' "${selected[@]}"

if [[ $DRY_RUN -eq 1 ]]; then
  info "dry-run: nada sera instalado."
  exit 0
fi

for id in "${selected[@]}"; do
  script="$PARTIALS_DIR/_$id.sh"
  if [[ -f "$script" ]]; then
    step "Executando $id"
    bash "$script"
  else
    warn "Partial ausente: $script"
  fi
done
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/run.sh`
Expected: todos `ok`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add init.sh tests/run.sh
git commit -m "feat: manifest-driven init with selection flags and dry-run"
```

---

### Task 3: Core base/shell partials

**Files:**
- Rewrite: `partials/_homebrew.sh`, `partials/_linuxbrew.sh`, `partials/_editor.sh`
- Create: `partials/_git.sh` (ajustar), `partials/_zsh.sh` (ajustar), `partials/_oh-my-zsh.sh` (ajustar), `partials/_xcode.sh` (manter)

**Interfaces:**
- Consumes: `lib/common.sh`.
- Produces: partials idempotentes para `xcode`, `homebrew`, `linuxbrew`, `git`, `zsh`, `oh-my-zsh`, `editor`.

- [ ] **Step 1: Write `_xcode.sh`** (mantém comportamento)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "xcode e so macOS"; exit 0; }
if xcode-select -p >/dev/null 2>&1; then
  info "Xcode CLT ja instalado"
else
  step "Instalando Xcode Command Line Tools"
  xcode-select --install
fi
```

- [ ] **Step 2: Write `_homebrew.sh`** (URL atualizada)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "homebrew e so macOS"; exit 0; }
if is_installed brew; then
  info "Homebrew ja instalado"
else
  step "Instalando Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
step "Atualizando Homebrew"
brew update
```

- [ ] **Step 3: Write `_linuxbrew.sh`** (Linuxbrew -> Homebrew)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == linux ]] || { warn "linuxbrew e so Linux"; exit 0; }
if is_installed brew; then
  info "Homebrew ja instalado"
else
  step "Instalando Homebrew (Linux)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  write_zshrc 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
step "Atualizando Homebrew"
brew update
```

- [ ] **Step 4: Write `_git.sh`** (editor config sai daqui)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed git; then info "git ja instalado"; else step "Instalando git"; brew install git; fi
```

- [ ] **Step 5: Write `_zsh.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed zsh; then info "zsh ja instalado"; else step "Instalando zsh"; brew install zsh zsh-completions; fi
if [[ "$SHELL" != *zsh ]]; then
  step "Definindo zsh como shell padrao"
  command -v zsh | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$(command -v zsh)" "$USER"
fi
```

- [ ] **Step 6: Write `_oh-my-zsh.sh`** (URL atualizada + plugins)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  info "Oh My Zsh ja instalado"
else
  step "Instalando Oh My Zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if ! is_installed zsh-autosuggestions; then
  step "Instalando zsh-autosuggestions"
  brew install zsh-autosuggestions
fi

if grep -q '^plugins=' "$HOME/.zshrc" 2>/dev/null; then
  sed -i.bak 's/^plugins=.*/plugins=(git zsh-autosuggestions)/' "$HOME/.zshrc"
else
  write_zshrc 'plugins=(git zsh-autosuggestions)'
fi
```

- [ ] **Step 7: Write `_editor.sh`** (config real)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed code; then EDITOR_CMD="code --wait"; else EDITOR_CMD="nano"; fi
step "Configurando EDITOR=$EDITOR_CMD"
write_zshrc "export EDITOR='$EDITOR_CMD'"
git config --global core.editor "$EDITOR_CMD"
```

- [ ] **Step 8: Verify + Commit**

Run: `bash -n partials/_xcode.sh partials/_homebrew.sh partials/_linuxbrew.sh partials/_git.sh partials/_zsh.sh partials/_oh-my-zsh.sh partials/_editor.sh`
Expected: exit 0.

```bash
git add partials/_xcode.sh partials/_homebrew.sh partials/_linuxbrew.sh partials/_git.sh partials/_zsh.sh partials/_oh-my-zsh.sh partials/_editor.sh
git commit -m "feat: update base and shell partials to current commands"
```

---

### Task 4: Core runtime partials

**Files:**
- Rewrite: `partials/_node.sh`, `partials/_ruby.sh`
- Create: `partials/_pnpm.sh`, `partials/_python.sh`

**Interfaces:**
- Consumes: `lib/common.sh`.
- Produces: `node` (fnm + LTS), `pnpm`, `ruby` (rbenv), `python`.

- [ ] **Step 1: Write `_node.sh`** (fnm + LTS)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed fnm; then info "fnm ja instalado"; else step "Instalando fnm"; brew install fnm; fi
write_zshrc 'eval "$(fnm env --use-on-cd)"'
eval "$(fnm env --use-on-cd)"
step "Instalando Node LTS"
fnm install --lts
fnm default lts
node -v
```

- [ ] **Step 2: Write `_pnpm.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed pnpm; then info "pnpm ja instalado"; else step "Instalando pnpm"; brew install pnpm; fi
```

- [ ] **Step 3: Write `_ruby.sh`** (rbenv)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed rbenv; then info "rbenv ja instalado"; else step "Instalando rbenv"; brew install rbenv ruby-build; fi
write_zshrc 'eval "$(rbenv init - zsh)"'
eval "$(rbenv init - zsh)"

latest="$(rbenv install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)"
if rbenv versions | grep -qF "$latest"; then
  info "Ruby $latest ja instalado"
else
  step "Instalando Ruby $latest"
  rbenv install "$latest"
fi
rbenv global "$latest"
ruby -v
```

- [ ] **Step 4: Write `_python.sh`** (ultima estavel)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed python3; then info "python3 ja instalado"; else step "Instalando Python"; brew install python; fi
```

- [ ] **Step 5: Verify + Commit**

Run: `bash -n partials/_node.sh partials/_pnpm.sh partials/_ruby.sh partials/_python.sh`
Expected: exit 0.

```bash
git add partials/_node.sh partials/_pnpm.sh partials/_ruby.sh partials/_python.sh
git commit -m "feat: fnm, pnpm, rbenv and python runtime partials"
```

---

### Task 5: Core clis/cloud/containers partials

**Files:**
- Create: `partials/_claude.sh`, `partials/_opencode.sh`, `partials/_rtk.sh`, `partials/_gh.sh`, `partials/_docker.sh`

**Interfaces:**
- Consumes: `lib/common.sh`.
- Produces: `claude`, `opencode`, `rtk`, `gh`, `docker`.

- [ ] **Step 1: Write `_claude.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed claude; then info "claude ja instalado"; else step "Instalando Claude Code"; curl -fsSL https://claude.ai/install.sh | bash; fi
```

- [ ] **Step 2: Write `_opencode.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed opencode; then info "opencode ja instalado"; else step "Instalando opencode"; brew tap anomalyco/tap && brew install opencode; fi
```

- [ ] **Step 3: Write `_rtk.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed rtk; then info "rtk ja instalado"; else step "Instalando rtk"; brew tap anomalyco/tap && brew install rtk; fi
```

- [ ] **Step 4: Write `_gh.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed gh; then info "gh ja instalado"; else step "Instalando gh"; brew install gh; fi
```

- [ ] **Step 5: Write `_docker.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed docker; then
  info "docker ja instalado"
elif [[ "$OS" == mac ]]; then
  step "Instalando Docker Desktop"
  brew install --cask docker
else
  step "Instalando Docker Engine"
  curl -fsSL https://get.docker.com | sh
fi
```

- [ ] **Step 6: Verify + Commit**

Run: `bash -n partials/_claude.sh partials/_opencode.sh partials/_rtk.sh partials/_gh.sh partials/_docker.sh`
Expected: exit 0.

```bash
git add partials/_claude.sh partials/_opencode.sh partials/_rtk.sh partials/_gh.sh partials/_docker.sh
git commit -m "feat: add claude, opencode, rtk, gh and docker partials"
```

---

### Task 6: `reactNative` partial

**Files:**
- Rewrite: `partials/_reactNative.sh`

**Interfaces:**
- Consumes: `lib/common.sh`.
- Produces: watchman, CocoaPods (só mac), zulu@17, android-commandlinetools + SDK, eas-cli.

- [ ] **Step 1: Write `_reactNative.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed watchman; then info "watchman ja instalado"; else step "Instalando watchman"; brew install watchman; fi

if [[ "$OS" == mac ]]; then
  step "Instalando CocoaPods (via rbenv)"
  gem install cocoapods
else
  info "Linux: build Android-only (sem CocoaPods)"
fi

if brew list --cask zulu@17 >/dev/null 2>&1; then info "zulu@17 ja instalado"; else step "Instalando zulu@17"; brew install --cask zulu@17; fi

if brew list --cask android-commandlinetools >/dev/null 2>&1; then info "android-commandlinetools ja instalado"; else step "Instalando android-commandlinetools"; brew install --cask android-commandlinetools; fi

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
step "Instalando componentes do Android SDK"
yes | sdkmanager --licenses
sdkmanager --install "platform-tools" "platforms;android-35" "build-tools;35.0.0" "emulator" "ndk;27.1.12297006" "system-images;android-35;google_apis;arm64-v8a"

write_zshrc "export ANDROID_HOME=$ANDROID_HOME"
write_zshrc 'export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools'

if is_installed eas; then info "eas-cli ja instalado"; else step "Instalando eas-cli"; npm install -g eas-cli; fi
```

- [ ] **Step 2: Verify + Commit**

Run: `bash -n partials/_reactNative.sh`
Expected: exit 0.

```bash
git add partials/_reactNative.sh
git commit -m "feat: react native partial with JDK 17, sdk cli and eas-cli"
```

---

### Task 7: Optional cloud/utils partials

**Files:**
- Create: `partials/_supabase.sh`, `partials/_aws.sh`, `partials/_firebase.sh`, `partials/_wrangler.sh`, `partials/_bitbucket.sh`, `partials/_horusec.sh`, `partials/_poetry.sh`, `partials/_ripgrep.sh`, `partials/_jq.sh`

**Interfaces:**
- Consumes: `lib/common.sh`.
- Produces: partials opcionais idempotentes.

- [ ] **Step 1: Write `_supabase.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed supabase; then info "supabase ja instalado"; else step "Instalando supabase"; brew install supabase; fi
```

- [ ] **Step 2: Write `_aws.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed aws; then info "aws ja instalado"; else step "Instalando awscli"; brew install awscli; fi
```

- [ ] **Step 3: Write `_firebase.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed firebase; then info "firebase ja instalado"; else step "Instalando firebase-tools"; npm install -g firebase-tools; fi
```

- [ ] **Step 4: Write `_wrangler.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed wrangler; then info "wrangler ja instalado"; else step "Instalando wrangler"; npm install -g wrangler; fi
```

- [ ] **Step 5: Write `_bitbucket.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed atlassian; then info "atlassian ja instalado"; else step "Instalando Atlassian CLI"; brew install --cask atlassian; fi
```

- [ ] **Step 6: Write `_horusec.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed horusec; then info "horusec ja instalado"; else step "Instalando horusec"; curl -fsSL https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh | bash; fi
```

- [ ] **Step 7: Write `_poetry.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed poetry; then info "poetry ja instalado"; else step "Instalando poetry"; brew install poetry; fi
```

- [ ] **Step 8: Write `_ripgrep.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed rg; then info "ripgrep ja instalado"; else step "Instalando ripgrep"; brew install ripgrep; fi
```

- [ ] **Step 9: Write `_jq.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
if is_installed jq; then info "jq ja instalado"; else step "Instalando jq"; brew install jq; fi
```

- [ ] **Step 10: Verify + Commit**

Run: `bash -n partials/_supabase.sh partials/_aws.sh partials/_firebase.sh partials/_wrangler.sh partials/_bitbucket.sh partials/_horusec.sh partials/_poetry.sh partials/_ripgrep.sh partials/_jq.sh`
Expected: exit 0.

```bash
git add partials/_supabase.sh partials/_aws.sh partials/_firebase.sh partials/_wrangler.sh partials/_bitbucket.sh partials/_horusec.sh partials/_poetry.sh partials/_ripgrep.sh partials/_jq.sh
git commit -m "feat: add optional cloud and utils partials"
```

---

### Task 8: Optional apps partials

**Files:**
- Rewrite: `partials/_vscode.sh`, `partials/_fonts.sh`
- Create: `partials/_ghostty.sh`, `partials/_obsidian.sh`, `partials/_axe.sh`, `partials/_mole.sh`

**Interfaces:**
- Consumes: `lib/common.sh`.
- Produces: `vscode` (segmentado), `fonts`, `ghostty`, `obsidian`, `axe`, `mole`.

- [ ] **Step 1: Write `_vscode.sh`** (segmentado)

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if is_installed code; then info "VS Code ja instalado"; exit 0; fi
if [[ "$OS" == mac ]]; then
  step "Instalando VS Code (cask)"
  brew install --cask visual-studio-code
else
  step "Instalando VS Code (apt)"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y code
fi
```

- [ ] **Step 2: Write `_fonts.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if brew list --cask font-fira-code >/dev/null 2>&1; then
  info "Fira Code ja instalada"
else
  step "Instalando Fira Code"
  brew tap homebrew/cask-fonts
  brew install --cask font-fira-code
fi
```

- [ ] **Step 3: Write `_ghostty.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "ghostty e so macOS"; exit 0; }
if brew list --cask ghostty >/dev/null 2>&1; then info "ghostty ja instalado"; else step "Instalando ghostty"; brew install --cask ghostty; fi
```

- [ ] **Step 4: Write `_obsidian.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "obsidian e so macOS"; exit 0; }
if brew list --cask obsidian >/dev/null 2>&1; then info "obsidian ja instalado"; else step "Instalando obsidian"; brew install --cask obsidian; fi
```

- [ ] **Step 5: Write `_axe.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "axe e so macOS"; exit 0; }
if brew list axe >/dev/null 2>&1; then info "axe ja instalado"; else step "Instalando AXe"; brew tap cameroncooke/axe && brew install axe; fi
```

- [ ] **Step 6: Write `_mole.sh`**

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[[ "$OS" == mac ]] || { warn "mole e so macOS"; exit 0; }
if is_installed mole; then info "mole ja instalado"; else step "Instalando mole"; brew install mole; fi
```

- [ ] **Step 7: Verify + Commit**

Run: `bash -n partials/_vscode.sh partials/_fonts.sh partials/_ghostty.sh partials/_obsidian.sh partials/_axe.sh partials/_mole.sh`
Expected: exit 0.

```bash
git add partials/_vscode.sh partials/_fonts.sh partials/_ghostty.sh partials/_obsidian.sh partials/_axe.sh partials/_mole.sh
git commit -m "feat: add optional app partials"
```

---

### Task 9: Remover obsoletos + README + verificacao final

**Files:**
- Delete: `partials/_jekyll.sh`, `partials/_apache.sh`, `partials/_aula.sh`, `partials/_atom-pdf.sh`, `partials/_hide-icons.sh`, `partials/_mongodb.sh`
- Create: `scripts/gen_readme.sh`
- Rewrite: `README.md` (gerado)

**Interfaces:**
- Consumes: `setup.tsv`.
- Produces: repo sem partials mortos; `scripts/gen_readme.sh` gera `README.md` a partir do manifest.

- [ ] **Step 1: Delete obsolete partials**

```bash
rm partials/_jekyll.sh partials/_apache.sh partials/_aula.sh partials/_atom-pdf.sh partials/_hide-icons.sh partials/_mongodb.sh
```

- [ ] **Step 2: Create `scripts/gen_readme.sh`**

```bash
#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/setup.tsv"

{
  cat <<'EOF'
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
EOF

  awk '!/^#/ && NF>=5 && $3=="core" { d=""; for(i=5;i<=NF;i++) d=(d==""?"":d" ")$i; printf "| %s | %s | %s | %s |\n", $1, $2, $4, d }' "$MANIFEST"

  cat <<'EOF'

## Opcional

| id | os | grupo | descricao |
|----|----|-------|-----------|
EOF

  awk '!/^#/ && NF>=5 && $3=="optional" { d=""; for(i=5;i<=NF;i++) d=(d==""?"":d" ")$i; printf "| %s | %s | %s | %s |\n", $1, $2, $4, d }' "$MANIFEST"

  cat <<'EOF'

## Regras

- Sempre versoes estaveis/LTS (Node via fnm, Ruby via rbenv, Python ultima estavel, JDK 17).
- Todo config vai para `~/.zshrc`.
EOF
} > "$ROOT/README.md"

echo "README.md gerado."
```

- [ ] **Step 3: Generate README**

Run: `bash scripts/gen_readme.sh`
Expected: `README.md gerado.` e arquivo com tabelas core/opcional.

- [ ] **Step 4: Final verification (full test + dry-run)**

Run: `bash tests/run.sh`
Expected: todos `ok`, exit 0.

Run: `./init.sh --dry-run --full`
Expected: lista todos os ids aplicaveis ao OS atual (no macOS, inclui `ghostty`, `obsidian`, `axe`, `mole`, `xcode`, `homebrew`; exclui `linuxbrew`).

Run: `./init.sh --dry-run --only node`
Expected: lista apenas `node`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove obsolete partials, add readme generator"
```

---

## Self-Review Notes

- Spec coverage: todas as secoes da spec (regras, manifest, selecao, Android SDK CLI-only, padronizacao .zshrc, remocoes) mapeiam para tarefas acima.
- `_git.sh` original configurava `core.editor`; isso foi movido para `_editor.sh` (evita duplicacao).
- `reactNative` e marcado `both` no manifest, mas internamente faz `if [[ "$OS" == mac ]]` para CocoaPods (Linux Android-only), conforme spec.
