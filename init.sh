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
