#!/bin/bash

set -e

cd tmp

# Download extension versions from MS
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.9.0/Ubuntu2004-7.3.tar | tar xf - --strip-components=1 Ubuntu2004-7.3/php_pdo_sqlsrv_73_nts.so Ubuntu2004-7.3/php_sqlsrv_73_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.9.0/Ubuntu2004-7.4.tar | tar xf - --strip-components=1 Ubuntu2004-7.4/php_pdo_sqlsrv_74_nts.so Ubuntu2004-7.4/php_sqlsrv_74_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.9.0/Ubuntu2004-8.0.tar | tar xf - --strip-components=1 Ubuntu2004-8.0/php_pdo_sqlsrv_80_nts.so Ubuntu2004-8.0/php_sqlsrv_80_nts.so

# Copy extensions to appropriate locations for each PHP version
mv php_pdo_sqlsrv_73_nts.so "$(php7.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_73_nts.so "$(php7.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_74_nts.so "$(php7.4 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_74_nts.so "$(php7.4 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"

# Copy conf file to appropriate locations
for PHP_VERSION in 7.3 7.4 8.0;do
    cp /mods-available/sqlsrv.ini "/etc/php/${PHP_VERSION}/mods-available/sqlsrv.ini"
done
