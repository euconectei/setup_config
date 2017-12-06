#!/bin/bash 

ruby -v
if [ $? -eq 0 ]; then
    echo "Ruby already installed!"
else
    echo "Installing Ruby"
    sudo apt-get install ruby-full
fi