#!/bin/bash 

git --version

if [ $? -eq 0 ]; then
    echo "Git already installed!"
else
    echo "Install Git"
    brew install git

    echo "Verify Git Version"
    git --version
fi

# https://blog.geekhunter.com.br/visual-studio-code-como-editor-do-git/
echo "Adding vscode as default editor on Git"
git config --global core.editor 'code --wait'
