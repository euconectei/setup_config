#!/bin/bash

mongo --version

if [ $? -eq 0 ]; then
    echo "MongoDB already installed!"
else
    echo "Installing MongoDB"
    brew install mongodb

    echo "Configuring MongoDB"
    # https://gist.github.com/adamgibbons/cc7b263ab3d52924d83b
    sudo mkdir -p /data/db
    sudo chmod 0755 /data/db
    sudo chown $USER /data/db
fi