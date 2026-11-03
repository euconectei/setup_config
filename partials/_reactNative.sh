#!/bin/bash
# Contrato: check() -> 0 se instalado e funcional; install() -> instala/repara.
# Carregado pelo bin/setup num subshell com lib/common.sh e o ambiente ja carregados.

if [[ "$ARCH" == arm64 ]]; then SYS_IMG_ABI=arm64-v8a; else SYS_IMG_ABI=x86_64; fi
SDK_PKGS=(
  "platform-tools"
  "platforms;android-35"
  "build-tools;35.0.0"
  "emulator"
  "ndk;27.1.12297006"
  "system-images;android-35;google_apis;$SYS_IMG_ABI"
)

# "platforms;android-35" -> $ANDROID_HOME/platforms/android-35
sdk_pkg_dir() { echo "$ANDROID_HOME/${1//;//}"; }

sdk_missing() {
  local p
  for p in "${SDK_PKGS[@]}"; do [[ -d "$(sdk_pkg_dir "$p")" ]] || echo "$p"; done
}

java17_ok() {
  if [[ "$OS" == mac ]]; then /usr/libexec/java_home -v 17 >/dev/null 2>&1; else has java; fi
}

pods_ok() {
  [[ "$OS" != mac ]] && return 0
  has pod && [[ "$(command -v pod)" == *rbenv* ]]
}

check() {
  has watchman && java17_ok && pods_ok && has sdkmanager && [[ -z "$(sdk_missing)" ]] && has eas
}

install() {
  brew_install watchman

  if [[ "$OS" == mac ]]; then
    # precisa do Ruby do rbenv; com o Ruby do sistema o gem install falha por permissao
    if [[ "$(rbenv version-name 2>/dev/null)" == system ]] || ! has rbenv; then
      err "Ruby do rbenv nao esta ativo (rode: setup --only ruby)"
      return 1
    fi
    if ! pods_ok; then
      step "Instalando CocoaPods (via rbenv)"
      retry gem install cocoapods
      rbenv rehash
    fi
  else
    info "Linux: build Android-only (sem CocoaPods)"
  fi

  brew_cask zulu@17 android-commandlinetools
  load_env

  local missing=()
  local p
  while IFS= read -r p; do [[ -n "$p" ]] && missing+=("$p"); done < <(sdk_missing)
  if [[ ${#missing[@]} -gt 0 ]]; then
    mkdir -p "$ANDROID_HOME"
    step "Aceitando licencas do Android SDK"
    # "yes" recebe SIGPIPE quando o sdkmanager termina; com pipefail isso abortava o script
    { yes 2>/dev/null || true; } | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null
    step "Instalando componentes do Android SDK: ${missing[*]}"
    retry sdkmanager --sdk_root="$ANDROID_HOME" --install "${missing[@]}"
  fi

  npm_global eas-cli eas
}
