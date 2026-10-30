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
