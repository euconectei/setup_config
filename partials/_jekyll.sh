#!/bin/bash 

jekyll -v

if [ $? -eq 0 ]; then
  echo "Jekyll already installed!"
else
  echo "Installing Jekyll"
  gem install jekyll
fi
