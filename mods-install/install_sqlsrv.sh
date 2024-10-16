#!/bin/bash

set -e

cd tmp

# Download extension versions from MS
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.9.0/Ubuntu2004-7.3.tar | tar xf - --strip-components=1 Ubuntu2004-7.3/php_pdo_sqlsrv_73_nts.so Ubuntu2004-7.3/php_sqlsrv_73_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.10.1/Ubuntu2004-7.4.tar | tar xf - --strip-components=1 Ubuntu2004-7.4/php_pdo_sqlsrv_74_nts.so Ubuntu2004-7.4/php_sqlsrv_74_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.11.1/Ubuntu2204-8.0.tar | tar xf - --strip-components=1 Ubuntu2204-8.0/php_pdo_sqlsrv_80_nts.so Ubuntu2204-8.0/php_sqlsrv_80_nts.so
curl -L https://github.com/microsoft/msphpsql/releases/download/v5.12.0/Linux_5.12.0RTW.tar.gz | tar xzf - --strip-components=2 \
    ./Linux/PDO_SQLSRV_8.1_NTS.so ./Linux/SQLSRV_8.1_NTS.so \
    ./Linux/PDO_SQLSRV_8.2_NTS.so ./Linux/SQLSRV_8.2_NTS.so \
    ./Linux/PDO_SQLSRV_8.3_NTS.so ./Linux/SQLSRV_8.3_NTS.so

# Copy extensions to appropriate locations for each PHP version
mv php_pdo_sqlsrv_73_nts.so "$(php7.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_73_nts.so "$(php7.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_74_nts.so "$(php7.4 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_74_nts.so "$(php7.4 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv php_pdo_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv php_sqlsrv_80_nts.so "$(php8.0 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv PDO_SQLSRV_8.1_NTS.so "$(php8.1 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv SQLSRV_8.1_NTS.so "$(php8.1 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv PDO_SQLSRV_8.2_NTS.so "$(php8.2 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv SQLSRV_8.2_NTS.so "$(php8.2 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"
mv PDO_SQLSRV_8.3_NTS.so "$(php8.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/pdo_sqlsrv.so"
mv SQLSRV_8.3_NTS.so "$(php8.3 -i | grep -P '^extension_dir' | sed -E -e 's/^extension_dir\s+=>\s+\S+\s+=>\s+(.*)$/\1/')/sqlsrv.so"

# Copy conf file to appropriate locations
for PHP_VERSION in 7.3 7.4 8.0 8.1 8.2 8.3; do
    cp /mods-available/sqlsrv.ini "/etc/php/${PHP_VERSION}/mods-available/sqlsrv.ini"
done
