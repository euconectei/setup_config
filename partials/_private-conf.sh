#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Private config (not versioned): copies *.conf from a private directory (e.g. a
# private notes vault) into ~/.config/setup_config/. Never overwrites local files;
# warns when a local file differs from the private copy.
#
# The private directory comes from $SETUP_PRIVATE_DIR (saved on first use) or from
# ~/.config/setup_config/private-dir (a single line with the path).

CONF_DIR="$HOME/.config/setup_config"
PTR="$CONF_DIR/private-dir"

src_dir() {
  local d="${SETUP_PRIVATE_DIR:-}"
  [[ -z "$d" && -f "$PTR" ]] && d="$(head -1 "$PTR")"
  echo "${d/#\~/$HOME}"
}
pending() {
  local d f; d="$(src_dir)"
  for f in "$d"/*.conf; do
    [[ -e "$f" ]] || continue
    [[ -f "$CONF_DIR/$(basename "$f")" ]] || echo "$f"
  done
}

# ok when the source dir is saved in $PTR (and matches $SETUP_PRIVATE_DIR, if given) and nothing is pending
check() {
  local d saved=""; d="$(src_dir)"
  if [[ -f "$PTR" ]]; then saved="$(head -1 "$PTR")"; fi
  [[ -n "$d" && -d "$d" && -n "$saved" && "$saved" == "${SETUP_PRIVATE_DIR:-$saved}" && -z "$(pending)" ]]
}

install() {
  local d f dst; d="$(src_dir)"
  if [[ -z "$d" ]]; then
    info "sem pasta privada: rode com SETUP_PRIVATE_DIR=<pasta com os .conf> ou grave o caminho em $PTR"
    return 0
  fi
  if [[ ! -d "$d" ]]; then
    warn "pasta privada nao encontrada: $d (clone/sincronize as notas privadas antes)"
    return 0
  fi
  mkdir -p "$CONF_DIR"
  if [[ -n "${SETUP_PRIVATE_DIR:-}" ]]; then echo "$SETUP_PRIVATE_DIR" > "$PTR"; fi
  for f in "$d"/*.conf; do
    [[ -e "$f" ]] || continue
    dst="$CONF_DIR/$(basename "$f")"
    if [[ ! -f "$dst" ]]; then
      step "copiando $(basename "$f")"; cp "$f" "$dst"; chmod 600 "$dst"
    elif ! cmp -s "$f" "$dst"; then
      warn "$(basename "$f") difere da copia privada (mantido o local): diff \"$f\" \"$dst\""
    fi
  done
}
