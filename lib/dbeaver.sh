#!/bin/bash
# Shared helpers for the dbeaver-sync item and bin/dbsync.
#
# Each DBeaver project (connections in .dbeaver/data-sources.json + Scripts/) is a git
# repository cloned outside the DBeaver workspace and imported into DBeaver once per
# machine. Passwords (.dbeaver/credentials-config.json) never leave the machine: DBeaver
# encrypts them with a key that is the same in every install, so they are effectively
# plain text.
#
# Config (not versioned): ~/.config/setup_config/dbeaver-sync.conf
#   DBEAVER_PROJECTS=(
#     "<project name>|<git url>|<local path>"
#   )

DBEAVER_SYNC_CONF="${DBEAVER_SYNC_CONF:-$HOME/.config/setup_config/dbeaver-sync.conf}"
DBEAVER_WORKSPACE="${DBEAVER_WORKSPACE:-$HOME/Library/DBeaverData/workspace6}"
DBEAVER_SECRET=".dbeaver/credentials-config.json"
DBEAVER_IGNORE=(
  "$DBEAVER_SECRET"
  ".dbeaver/*.bak"
  ".metadata/"
  ".DS_Store"
)

# loads the config; fails when it is missing or lists no project
dbeaver_load() {
  DBEAVER_PROJECTS=()
  [[ -f "$DBEAVER_SYNC_CONF" ]] || return 1
  # shellcheck disable=SC1090
  source "$DBEAVER_SYNC_CONF"
  [[ ${#DBEAVER_PROJECTS[@]} -gt 0 ]]
}

# prints "name|url|dir" per project, with ~ expanded in dir
dbeaver_projects() {
  local entry name url dir
  for entry in "${DBEAVER_PROJECTS[@]}"; do
    IFS='|' read -r name url dir <<<"$entry"
    echo "$name|$url|${dir/#\~/$HOME}"
  done
}

# imported into DBeaver (Eclipse keeps per-project metadata once a project is registered)
dbeaver_registered() {
  [[ -d "$DBEAVER_WORKSPACE/.metadata/.plugins/org.eclipse.core.resources/.projects/$1" ]]
}

dbeaver_running() { pgrep -f "DBeaver.app/Contents/MacOS" >/dev/null 2>&1; }

# hook that refuses any commit containing the passwords file
dbeaver_hook_body() {
  cat <<EOF
#!/bin/sh
# Installed by setup_config (dbeaver-sync): DBeaver passwords never go to git.
if git diff --cached --name-only | grep -qxF '$DBEAVER_SECRET'; then
  echo "dbeaver-sync: commit recusado, $DBEAVER_SECRET contem senhas" >&2
  exit 1
fi
EOF
}

# the passwords file is ignored, untracked and guarded by the pre-commit hook
dbeaver_protected() {
  local dir="$1"
  git -C "$dir" check-ignore -q "$DBEAVER_SECRET" || return 1
  ! git -C "$dir" ls-files --error-unmatch "$DBEAVER_SECRET" >/dev/null 2>&1 || return 1
  cmp -s "$dir/.git/hooks/pre-commit" <(dbeaver_hook_body)
}

# adds missing ignore rules and installs the hook; fails if the passwords file is tracked
dbeaver_protect() {
  local dir="$1" rule
  touch "$dir/.gitignore"
  for rule in "${DBEAVER_IGNORE[@]}"; do
    grep -qxF "$rule" "$dir/.gitignore" || echo "$rule" >> "$dir/.gitignore"
  done
  dbeaver_hook_body > "$dir/.git/hooks/pre-commit"
  chmod +x "$dir/.git/hooks/pre-commit"
  if git -C "$dir" ls-files --error-unmatch "$DBEAVER_SECRET" >/dev/null 2>&1; then
    echo "$DBEAVER_SECRET esta versionado em $dir: remova do historico antes de sincronizar" >&2
    return 1
  fi
}
