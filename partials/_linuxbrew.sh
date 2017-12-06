#!/bin/bash 

brew -v

if [ $? -eq 0 ]; then
    echo "linuxbrew já instalado!"
else
    echo "Install linuxbrew"
    sudo apt-get install build-essential curl file git python-setuptools
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
    echo "export PATH='$(brew --prefix)/bin:$(brew --prefix)/sbin'":'"$PATH"' >>~/.bashrc
fi
echo "Verify if Homebrew is ok"
brew doctor

echo "Update Homebrew"
brew update