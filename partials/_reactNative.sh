echo 'Installing React Native dependecies'
brew install node
brew install watchman

echo 'iOS dependencies'
sudo gem install cocoapods

echo 'Android dependencies'
brew tap homebrew/cask-versions
brew install --cask zulu11

echo "export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk \n
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator \n
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools"