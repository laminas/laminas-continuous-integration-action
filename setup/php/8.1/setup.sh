#!/bin/bash

curl -sSLO https://github.com/shivammathur/php-builder/releases/latest/download/install.sh
chmod a+x ./install.sh
./install.sh 8.1

# Keep modules we do have in PHP 8.0 as well while disabling all other modules
for moduleIniSettings in /etc/php/8.1/cli/conf.d/*; do
    moduleName=$(echo "$(basename $(readlink $moduleIniSettings))" | cut -d '.' -f1)

    case "$moduleName" in
        "bz2" | "calendar" | "ctype" | "curl" | "dom" | "exif" | "ffi" | "fileinfo" | "ftp" | "gettext" | "iconv" | "intl" | "mbstring" | "opcache" | "pdo" | "phar" | "posix" | "readline" | "shmop" | "simplexml" | "sockets" | "sysvmsg" | "sysvsem" | "sysvshm" | "tokenizer" | "xml" | "xmlreader" | "xmlwriter" | "xsl" | "zip")
        ;;
        *)
            rm "$moduleIniSettings"
        ;;
    esac
done

# Prepares the configuration the same way as mods-install/install_sqlsrv.sh would do
cat /etc/php/8.1/mods-available/pdo_sqlsrv.ini >> /etc/php/8.1/mods-available/sqlsrv.ini
rm /etc/php/8.1/mods-available/pdo_sqlsrv.ini
