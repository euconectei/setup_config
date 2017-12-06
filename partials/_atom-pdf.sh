#!/bin/bash 

apm -v

if [ $? -eq 0 ]; then
  echo "Atom already installed!"
  echo "Installing markdown-pdf on Atom.io"
  apm install markdown-pdf
else
  echo "Atom not installed"
fi

