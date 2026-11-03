#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

# Docker via Colima: bem mais leve que o Docker Desktop (importante com 8 GB de RAM).
# Uso:  colima start   (sob demanda)  |  colima stop  (libera a memoria)
COLIMA_ARGS=(--cpu 2 --memory 3 --disk 40 --vm-type vz --vz-rosetta --mount-type virtiofs)

docker_config_ok() {
  local cfg="$HOME/.docker/config.json"
  [[ -f "$cfg" ]] && grep -q cli-plugins "$cfg" && ! grep -q "\"credsStore\": *\"desktop\"" "$cfg"
}

check() {
  has colima && has docker && docker compose version >/dev/null 2>&1 \
    && [[ -d "$HOME/.colima/default" ]] && docker_config_ok && [[ ! -d /Applications/Docker.app ]]
}

install() {
  if brew_has_cask docker-desktop || brew_has_cask docker || [[ -d /Applications/Docker.app ]]; then
    step "Removendo Docker Desktop (substituido por Colima)"
    osascript -e "quit app \"Docker\"" >/dev/null 2>&1 || true
    brew uninstall --cask docker-desktop 2>/dev/null || brew uninstall --cask docker 2>/dev/null || sudo rm -rf /Applications/Docker.app
  fi

  brew_install colima docker docker-compose docker-buildx docker-credential-helper
  hash -r

  # plugins compose/buildx do brew + troca o credsStore "desktop" (deixado pelo Docker Desktop,
  # quebra o docker pull depois que ele e removido) pelo keychain do macOS
  mkdir -p "$HOME/.docker"
  local cfg="$HOME/.docker/config.json"
  [[ -f "$cfg" ]] && backup_file "$cfg"
  /usr/bin/python3 - "$cfg" "$(brew --prefix)/lib/docker/cli-plugins" <<"PY"
import json, os, sys
path, plugins = sys.argv[1], sys.argv[2]
cfg = {}
if os.path.exists(path):
    try: cfg = json.load(open(path))
    except Exception: cfg = {}
dirs = cfg.get("cliPluginsExtraDirs", [])
if plugins not in dirs: dirs.append(plugins)
cfg["cliPluginsExtraDirs"] = dirs
if cfg.get("credsStore") in (None, "desktop"): cfg["credsStore"] = "osxkeychain"
json.dump(cfg, open(path, "w"), indent=2)
PY

  if [[ ! -d "$HOME/.colima/default" ]]; then
    step "Criando VM do Colima (2 CPU, 3 GB RAM) e desligando em seguida"
    colima start "${COLIMA_ARGS[@]}"
    docker run --rm hello-world >/dev/null && info "docker funcionando"
    colima stop
  fi
  info "use: colima start (quando precisar) / colima stop (para liberar memoria)"
}
