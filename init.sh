#!/bin/bash

# Select the configs 
sw=('git' 'zsh' 'oh-my-zsh' 'node' 'mongodb')

# Verify your O.S.
if [ "$(uname)" == 'Darwin' ]; then
  OS='Mac'
  sw=('xcode' 'homebrew' 'editor' ${sw[@]})
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  OS='Linux'
  sw=('ruby' 'linuxbrew' ${sw[@]})
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi

# Path of config files
path='partials/_'
readonly path

# Execute configs
for i in "${sw[@]}"
do
  bash './'$path$i'.sh'
done
