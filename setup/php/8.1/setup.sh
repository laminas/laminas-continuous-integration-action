#!/bin/bash

curl -sSLO https://github.com/shivammathur/php-builder/releases/latest/download/install.sh
chmod a+x ./install.sh
./install.sh 8.1

# Prepares the configuration the same way as mods-install/install_sqlsrv.sh would do
cat /etc/php/8.1/mods-available/pdo_sqlsrv.ini >> /etc/php/8.1/mods-available/sqlsrv.ini
rm /etc/php/8.1/mods-available/pdo_sqlsrv.ini
