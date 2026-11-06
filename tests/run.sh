#!/bin/bash
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
fail=0

ok()   { echo "ok  - $1"; }
bad()  { echo "FAIL- $1"; fail=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# isola estado/HOME para os testes nao tocarem no ambiente real
export HOME="$TMP/home" SETUP_STATE="$TMP/state"
mkdir -p "$HOME"

sel() { "$ROOT/bin/setup" --dry-run "$@" </dev/null 2>/dev/null | sed -n 's/^  //p'; }
has_id()  { grep -qx "$1" <<<"$2"; }

# 1) sintaxe
for f in init.sh install.sh bin/setup lib/*.sh partials/*.sh scripts/*.sh; do
  if bash -n "$f" 2>/dev/null; then ok "bash -n $f"; else bad "bash -n $f"; fi
done

# 2) contrato dos partials + cada id do manifesto tem partial
while read -r id _; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  p="partials/_$id.sh"
  if [[ ! -f "$p" ]]; then bad "partial ausente: $p"; continue; fi
  if (source lib/common.sh; source "$p"; declare -F check >/dev/null && declare -F install >/dev/null); then
    ok "contrato check/install: $id"
  else
    bad "contrato check/install: $id"
  fi
done < setup.tsv

# 2b) manifesto: toda dependencia vem antes do item (a ordem das linhas e a ordem de execucao)
seen=" "
while read -r id _ _ _ deps _; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  for d in ${deps//,/ }; do
    [[ "$d" == - || "$seen" == *" $d "* ]] || bad "manifesto: $id depende de $d, que vem depois"
  done
  seen+="$id "
done < setup.tsv
ok "manifesto: dependencias antes dos itens"

# 3) selecao
out=$(sel --only node)
has_id node "$out" && has_id homebrew "$out" && ! has_id ghostty "$out" \
  && ok "--only node inclui dependencia homebrew e exclui ghostty" || { bad "--only node"; echo "$out"; }

out=$(sel --core)
has_id node "$out" && ! has_id ghostty "$out" && ok "--core inclui node e exclui opcional" || { bad "--core"; echo "$out"; }

out=$(sel --full)
has_id ghostty "$out" && ok "--full inclui opcional ghostty (mac)" || { bad "--full"; echo "$out"; }

out=$(sel --group cloud)
has_id aws "$out" && has_id gh "$out" && ! has_id ghostty "$out" \
  && ok "--group cloud funciona (GROUPS era variavel reservada)" || { bad "--group cloud"; echo "$out"; }

out=$(sel --only firebase)
has_id node "$out" && [[ "$(grep -n '^node$' <<<"$out" | cut -d: -f1)" -lt "$(grep -n '^firebase$' <<<"$out" | cut -d: -f1)" ]] \
  && ok "dependencias resolvidas e ordenadas (node antes de firebase)" || { bad "deps firebase"; echo "$out"; }

printf '#!/bin/bash\ngrep -E " (jq|gh) "\n' > "$TMP/fzf"; chmod +x "$TMP/fzf"
out=$(SETUP_FZF="$TMP/fzf" sel --select)
has_id jq "$out" && has_id gh "$out" && ! has_id node "$out" \
  && ok "menu: extrai o id (antes extraia a descricao)" || { bad "menu"; echo "$out"; }

printf '#!/bin/bash\nhead -1\n' > "$TMP/fzf"   # Enter direto = linha destacada (a primeira)
out=$(SETUP_FZF="$TMP/fzf" sel --select)
has_id node "$out" && has_id docker "$out" && ! has_id ghostty "$out" \
  && ok "menu: Enter direto instala o core" || { bad "menu enter"; echo "$out"; }

printf '#!/bin/bash\ngrep -E " (core|jq) "\n' > "$TMP/fzf"
out=$(SETUP_FZF="$TMP/fzf" sel --select)
has_id node "$out" && has_id jq "$out" && ! has_id ghostty "$out" \
  && ok "menu: core + item opcional marcado" || { bad "menu core+jq"; echo "$out"; }

out=$(sel --full --skip horusec,jq)
has_id ghostty "$out" && ! has_id horusec "$out" && ! has_id jq "$out" \
  && ok "--full --skip exclui itens" || { bad "--skip"; echo "$out"; }

printf '#!/bin/bash\ngrep -v " horusec "\n' > "$TMP/fzf"   # Ctrl-A e desmarcar horusec
out=$(SETUP_FZF="$TMP/fzf" sel --select)
has_id ghostty "$out" && ! has_id horusec "$out" \
  && ok "menu: marcar tudo menos um" || { bad "menu select-all"; echo "$out"; }

mkdir -p "$SETUP_STATE"
echo jq > "$SETUP_STATE/desired"
out=$(sel)
has_id jq "$out" && has_id node "$out" && ok "sem opcoes: core + escolhas anteriores" || { bad "desired"; echo "$out"; }

echo jq > "$SETUP_STATE/failed"
out=$(sel --retry-failed)
has_id jq "$out" && ! has_id node "$out" && ok "--retry-failed so o que falhou" || { bad "retry-failed"; echo "$out"; }
rm -rf "$SETUP_STATE"

# 4) .zshrc: bloco gerenciado idempotente, no topo
printf 'plugins=(git)\nsource $ZSH/oh-my-zsh.sh\n' > "$HOME/.zshrc"
( source lib/common.sh; zshrc_block init 'echo a' top; zshrc_block init 'echo a' top; zshrc_block init 'echo b' top ) >/dev/null
if [[ "$(grep -c 'setup_config:init >>>' "$HOME/.zshrc")" == 1 ]] && head -1 "$HOME/.zshrc" | grep -q '>>> setup_config:init' \
   && grep -qx 'echo b' "$HOME/.zshrc" && ! grep -qx 'echo a' "$HOME/.zshrc"; then
  ok "zshrc_block idempotente e atualizado in-place"
else
  bad "zshrc_block"; cat "$HOME/.zshrc"
fi

# 4b) oh-my-zsh: adiciona zsh-autosuggestions preservando plugins existentes
mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"; touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"
for case in 'plugins=(git docker)' $'plugins=(\n  git\n  docker\n)'; do
  printf '%s\nsource $ZSH/oh-my-zsh.sh\n' "$case" > "$HOME/.zshrc"
  ( source lib/common.sh; source partials/_oh-my-zsh.sh; install >/dev/null; check ) \
    && grep -q docker "$HOME/.zshrc" && [[ "$(grep -c zsh-autosuggestions "$HOME/.zshrc")" == 1 ]] \
    && ok "oh-my-zsh: plugin adicionado sem perder os existentes ($(echo "$case" | head -1))" \
    || { bad "oh-my-zsh plugins"; cat "$HOME/.zshrc"; }
done
rm -rf "$HOME/.oh-my-zsh"

# 5) isolamento de falhas com partials falsos
FAKE="$TMP/fake"; mkdir -p "$FAKE/partials"
cp -R bin lib shell "$FAKE/"
cat > "$FAKE/setup.tsv" <<'EOF'
aa  both  core  base  -   quebra
bb  both  core  base  aa  depende de aa
cc  both  core  base  -   ok
EOF
printf 'check() { false; }\ninstall() { false; }\n' > "$FAKE/partials/_aa.sh"
printf 'check() { true; }\ninstall() { true; }\n'   > "$FAKE/partials/_bb.sh"
printf 'check() { [[ -f "$HOME/cc" ]]; }\ninstall() { touch "$HOME/cc"; }\n' > "$FAKE/partials/_cc.sh"
printf 'export EDITOR='"'"'nano'"'"'\n' > "$HOME/.zshrc"
out=$("$FAKE/bin/setup" --core </dev/null 2>&1); rc=$?
[[ $rc -ne 0 ]] && [[ -f "$HOME/cc" ]] && grep -qx aa "$SETUP_STATE/failed" && grep -qx bb "$SETUP_STATE/failed" \
  && ok "falha isolada: aa falha, bb pulado, cc instala; exit != 0" || { bad "isolamento"; echo "$out"; }
grep -q 'setup_config:init' "$HOME/.zshrc" && ! grep -qx "export EDITOR='nano'" "$HOME/.zshrc" \
  && ok "integracao no .zshrc + remocao de linha antiga" || { bad "migracao .zshrc"; cat "$HOME/.zshrc"; }
"$FAKE/bin/setup" --only cc </dev/null >/dev/null 2>&1
grep -qx aa "$SETUP_STATE/failed" && ok "falhas anteriores preservadas apos execucao parcial" || bad "failed preservado"
[[ ! -d "$SETUP_STATE/lock" ]] && ok "lock liberado" || bad "lock liberado"

# 6) dbeaver-sync: clona, protege as senhas e sincroniza entre duas "maquinas"
DB="$TMP/dbeaver"; mkdir -p "$DB"
git init -q --bare "$DB/remote.git"
seed="$DB/seed"; git clone -q "$DB/remote.git" "$seed" 2>/dev/null
mkdir -p "$seed/Scripts"; touch "$seed/Scripts/.gitkeep"
git -C "$seed" add -A && git -C "$seed" -c user.name=t -c user.email=t@t commit -qm init && git -C "$seed" push -q origin HEAD 2>/dev/null
dbsetup() {  # $1 = machine name
  ( export DBEAVER_SYNC_CONF="$DB/$1.conf" DBEAVER_WORKSPACE="$DB/ws-$1" SETUP_HOME="$ROOT"
    printf 'DBEAVER_PROJECTS=("Teste|%s|%s")\n' "$DB/remote.git" "$DB/$1/teste" > "$DBEAVER_SYNC_CONF"
    source lib/common.sh; source partials/_dbeaver-sync.sh; install >/dev/null 2>&1; check )
}
dbsync_on() { DBEAVER_SYNC_CONF="$DB/$1.conf" DBEAVER_WORKSPACE="$DB/ws-$1" bin/dbsync >>"$DB/log" 2>&1; }
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
dbsetup a && dbsetup b && ok "dbeaver-sync: clona e passa no check" || bad "dbeaver-sync install/check"

A="$DB/a/teste"; B="$DB/b/teste"
mkdir -p "$A/.dbeaver"; echo '{"x":1}' > "$A/.dbeaver/data-sources.json"; echo segredo > "$A/.dbeaver/credentials-config.json"
echo 'select 1;' > "$A/Scripts/q.sql"
dbsync_on a && dbsync_on b && [[ -f "$B/.dbeaver/data-sources.json" && -f "$B/Scripts/q.sql" ]] \
  && ok "dbsync: conexoes e scripts chegam na outra maquina" || bad "dbsync propagacao"
[[ ! -f "$B/.dbeaver/credentials-config.json" ]] && ! grep -q credentials <<<"$(git -C "$DB/remote.git" log --all --name-only --format=)" \
  && ok "dbsync: arquivo de senhas nunca vai para o git" || bad "dbsync vazou senhas"
git -C "$A" add -f .dbeaver/credentials-config.json && ! git -C "$A" commit -qm leak 2>/dev/null \
  && ok "dbeaver-sync: hook recusa commit forcado das senhas" || bad "hook pre-commit"
git -C "$A" reset -q
echo 'select 2;' > "$B/Scripts/q2.sql"; dbsync_on b
echo 'select 3;' > "$A/Scripts/q3.sql"; dbsync_on a \
  && [[ -f "$A/Scripts/q2.sql" ]] && grep -qx Scripts/q3.sql <<<"$(git -C "$DB/remote.git" log --all --format= --name-only)" \
  && ok "dbsync: alteracoes nas duas maquinas se juntam (rebase)" || { bad "dbsync rebase"; cat "$DB/log"; }
DBEAVER_SYNC_CONF="$DB/nao-existe.conf" bin/dbsync >/dev/null 2>&1 && bad "dbsync sem conf" || ok "dbsync: falha clara sem conf"

exit $fail
