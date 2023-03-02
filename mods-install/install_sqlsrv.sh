#!/bin/bash

set -e

cd tmp

# Download extension versions from MS
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.10.0/Ubuntu2004-8.0.tar | tar xf - --strip-components=1 Ubuntu2004-8.0/php_pdo_sqlsrv_80_nts.so Ubuntu2004-8.0/php_sqlsrv_80_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.10.0/Ubuntu2004-8.1.tar | tar xf - --strip-components=1 Ubuntu2004-8.1/php_pdo_sqlsrv_81_nts.so Ubuntu2004-8.1/php_sqlsrv_81_nts.so

# Copy extensions to appropriate locations for each PHP version
mv php_pdo_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_81_nts.so "$(php8.1 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_81_nts.so "$(php8.1 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"

# Copy conf file to appropriate locations
for PHP_VERSION in 8.0 8.1;do
    cp /mods-available/sqlsrv.ini "/etc/php/${PHP_VERSION}/mods-available/sqlsrv.ini"
done
