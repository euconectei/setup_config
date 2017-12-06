#!/bin/bash

node -v

if [ $? -eq 0 ]; then
    echo "NodeJS already installed!"
else
    echo "Installing NodeJS"
    brew install node
fi