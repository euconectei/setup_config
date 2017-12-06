#!/bin/bash 

brew -v
if [ $? -eq 0 ]; then
    echo "Homebrew already installed!"
else
    echo "Installing Homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi
echo "Verify if Homebrew is ok"
brew doctor

echo "Update Homebrew"
brew update