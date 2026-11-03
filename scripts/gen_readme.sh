#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/setup.tsv"

{
  cat <<'EOF'
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
EOF

  awk '!/^#/ && NF>=6 && $3=="core" { d=""; for(i=6;i<=NF;i++) d=(d==""?"":d" ")$i; printf "| %s | %s | %s | %s |\n", $1, $2, $4, d }' "$MANIFEST"

  cat <<'EOF'

## Opcional

| id | os | grupo | descricao |
|----|----|-------|-----------|
EOF

  awk '!/^#/ && NF>=6 && $3=="optional" { d=""; for(i=6;i<=NF;i++) d=(d==""?"":d" ")$i; printf "| %s | %s | %s | %s |\n", $1, $2, $4, d }' "$MANIFEST"

  cat <<'EOF'

## Regras

- Sempre versoes estaveis/LTS (Node via fnm, Ruby via rbenv, Python ultima estavel, JDK 17).
- Configuracao de shell centralizada em `shell/init.zsh`, carregada por um bloco gerenciado no `~/.zshrc`.
EOF
} > "$ROOT/README.md"

echo "README.md gerado."
