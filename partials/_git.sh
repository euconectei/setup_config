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