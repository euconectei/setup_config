#!/bin/bash 

user=$(whoami)
vHostFile=/etc/apache2/users/$user.conf

echo 'Criando arquivo de configuração'
sudo touch $vHostFile

vHostConfig="\<Directory \"/Users/$user/Sites/\"\> '\n'\
AllowOverride All '\n'\
Options Indexes MultiViews FollowSymLinks '\n'\
Require all granted '\n'\
\<\/Directory\>"


sudo bash -c "echo -e $vHostConfig >> $vHostFile"

echo 'Alterando permissão do arquivo de configuração'
sudo chmod 644 $vHostFile

echo 'Conferir módulos instalados'
readmeFile=/Users/$user/Desktop/TerminarConfiguracaoApache.txt
touch $readmeFile
readmeText='Open the main httpd.conf and allow some modules: \n \n
sudo nano /etc/apache2/httpd.conf \n \n
And make sure these modules are uncommented (the first 2 should already be on a clean install): \n \n

LoadModule authz_core_module libexec/apache2/mod_authz_core.so \n
LoadModule authz_host_module libexec/apache2/mod_authz_host.so \n
LoadModule userdir_module libexec/apache2/mod_userdir.so \n
LoadModule include_module libexec/apache2/mod_include.so \n
LoadModule rewrite_module libexec/apache2/mod_rewrite.so \n
LoadModule php5_module libexec/apache2/libphp5.so \n \n

Then open another Apache config file and uncomment another file: \n \n

sudo nano /etc/apache2/extra/httpd-userdir.conf \n \n

And uncomment: \n \n

Include /private/etc/apache2/users/*.conf'
echo $readmeText >> $readmeFile