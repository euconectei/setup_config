#!/bin/bash 

brew -v

if [ $? -eq 0 ]; then
    echo "Linuxbrew já instalado!"
else
    echo "Install Linuxbrew"
    sudo apt-get install build-essential curl file git python-setuptools
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
    echo "export PATH='/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin'":'"$PATH"' >> ~/.bashrc
fi
echo "Verify if Linuxbrew is ok"
brew doctor

echo "Update Linuxbrew"
brew update