#!/bin/bash

curl -sSLO https://github.com/shivammathur/php-builder/releases/latest/download/install.sh
chmod a+x ./install.sh
./install.sh 8.1

# Setup directory structure
CONFIGURATION_DIRECTORY_PREFIX="/usr/local/php/8.1/etc"

rm -rf /etc/php/8.1
mkdir -p /etc/php/8.1/{cli,mods-available}
ln -s $CONFIGURATION_DIRECTORY_PREFIX/php.ini /etc/php/8.1/cli/
ln -s $CONFIGURATION_DIRECTORY_PREFIX/conf.d /etc/php/8.1/cli/conf.d
for mod in /etc/php/8.1/cli/conf.d/*; do
    modWithoutPriority=$(echo $(basename $mod) | cut -d'-' -f2-)
    modname=$(echo $modWithoutPriority | cut -d'.' -f1)

    mv $mod /etc/php/8.1/mods-available/$modWithoutPriority

    case "$modname" in
        "xdebug" | "sqlsrv" | "pdo_sqlsrv")
            # Do not enable these modules as default
        ;;
        *)
            ln -s /etc/php/8.1/mods-available/$modWithoutPriority $mod
        ;;
    esac
done

# Prepares the configuration the same way as mods-install/install_sqlsrv.sh would do
cat /etc/php/8.1/mods-available/pdo_sqlsrv.ini >> /etc/php/8.1/mods-available/sqlsrv.ini
rm /etc/php/8.1/mods-available/pdo_sqlsrv.ini
