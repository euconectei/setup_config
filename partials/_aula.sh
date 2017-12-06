#!/bin/bash 

echo "Create .bashrc"
touch ~/.bashrc

echo "Configure Aulas"
echo 'alias aula="cd ~/Google\ Drive/UCB/Aulas && $EDITOR ."' >> ~/.bashrc 

echo "Markdown to Slides"
npm install -g markdown-to-slides

# export alias gerarSlides="markdown-to-slides -d $1.md -o $1.html -w --level 2 -i -l ../../aula-tpl.html"
echo 'function gS { markdown-to-slides -d $1.md -o $1.html -w --level 2 -i -l ../../aula-tpl.html }' >> ~/.bashrc 
echo 'alias gerarSlides=gS' >> ~/.bashrc 

echo 'source ~/.bashrc' >> ~/.zshrc


# https://www.vivaolinux.com.br/topico/Shell-Script/Como-achar-uma-palavra-especifica-no-arquivo-e-sabem-em-qual-linha-esta