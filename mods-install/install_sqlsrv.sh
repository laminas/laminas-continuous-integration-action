#!/bin/bash

set -e

cd tmp

# Download extension versions from MS
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.11.1/Ubuntu2204-8.0.tar | tar xf - --strip-components=1 Ubuntu2204-8.0/php_pdo_sqlsrv_80_nts.so Ubuntu2204-8.0/php_sqlsrv_80_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.12.0/Ubuntu2204-8.1.tar | tar xf - --strip-components=1 Ubuntu2204-8.1/php_pdo_sqlsrv_81_nts.so Ubuntu2204-8.1/php_sqlsrv_81_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.12.0/Ubuntu2204-8.2.tar | tar xf - --strip-components=1 Ubuntu2204-8.2/php_pdo_sqlsrv_82_nts.so Ubuntu2204-8.2/php_sqlsrv_82_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.12.0/Ubuntu2204-8.3.tar | tar xf - --strip-components=1 Ubuntu2204-8.3/php_pdo_sqlsrv_83_nts.so Ubuntu2204-8.3/php_sqlsrv_83_nts.so

# Copy extensions to appropriate locations for each PHP version
mv php_pdo_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_81_nts.so "$(php8.1 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_81_nts.so "$(php8.1 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_82_nts.so "$(php8.2 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_82_nts.so "$(php8.2 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_83_nts.so "$(php8.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_83_nts.so "$(php8.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"

# Copy conf file to appropriate locations
for PHP_VERSION in 8.0 8.1 8.2 8.3; do
    cp /mods-available/sqlsrv.ini "/etc/php/${PHP_VERSION}/mods-available/sqlsrv.ini"
done
