#!/bin/bash

zsh --version

if [ $? -eq 0 ]; then
    echo "ZSH already installed!"
else
    echo "Installing ZSH"
    brew install zsh zsh-completions
fi

command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"