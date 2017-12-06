#!/bin/bash

zsh -v

if [ $? -eq 0 ]; then
    echo "ZSH already installed!"
else
    echo "Installing ZSH"
    brew install zsh zsh-completions
fi