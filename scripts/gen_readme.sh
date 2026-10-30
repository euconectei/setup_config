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
