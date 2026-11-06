#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Syncs DBeaver projects (connections + scripts) between machines through private git
# repositories. Clones each project listed in ~/.config/setup_config/dbeaver-sync.conf
# (see lib/dbeaver.sh) and guards the passwords file. Day-to-day sync: dbsync.

source "$SETUP_HOME/lib/dbeaver.sh"

check() {
  dbeaver_load || return 1
  local name url dir
  while IFS='|' read -r name url dir; do
    [[ -d "$dir/.git" ]] || return 1
    [[ "$(git -C "$dir" remote get-url origin 2>/dev/null)" == "$url" ]] || return 1
    dbeaver_protected "$dir" || return 1
  done < <(dbeaver_projects)
}

install() {
  if ! dbeaver_load; then
    err "sem projetos: crie $DBEAVER_SYNC_CONF com DBEAVER_PROJECTS=(\"<nome>|<url git>|<pasta>\")"
    return 1
  fi
  local name url dir current rc=0
  while IFS='|' read -r name url dir; do
    if [[ ! -d "$dir/.git" ]]; then
      if [[ -d "$dir" && -n "$(ls -A "$dir")" ]]; then
        err "$dir existe e nao e um repositorio git"; rc=1; continue
      fi
      step "clonando o projeto $name"
      mkdir -p "$(dirname "$dir")"
      retry git clone "$url" "$dir" || { rc=1; continue; }
    fi
    current="$(git -C "$dir" remote get-url origin 2>/dev/null)"
    if [[ "$current" != "$url" ]]; then
      err "$dir aponta para $current (esperado: $url)"; rc=1; continue
    fi
    dbeaver_protect "$dir" || { rc=1; continue; }
    if ! dbeaver_registered "$name"; then
      info "importe o projeto $name no DBeaver uma vez: File > Import > General > Existing Projects into Workspace > $dir"
    fi
  done < <(dbeaver_projects)
  info "para sincronizar: dbsync"
  return $rc
}
