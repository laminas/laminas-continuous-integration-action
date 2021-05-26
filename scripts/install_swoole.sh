#!/bin/bash

set -e

SWOOLE_VERSION=4.6.7

# Get swoole package ONCE
cd /tmp
wget https://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz
tar xzf swoole-${SWOOLE_VERSION}.tgz

# We only need to support currently supported PHP versions
for PHP_VERSION in 7.3 7.4 8.0;do
    cd /tmp/swoole-${SWOOLE_VERSION}
    if [ -f Makefile ];then
        make clean
    fi
    phpize${PHP_VERSION}
    ./configure --enable-swoole --enable-sockets --with-php-config=php-config${PHP_VERSION}
    make
    make install
done

# Cleanup
rm -rf /tmp/swoole-${SWOOLE_VERSION}
rm /tmp/swoole-${SWOOLE_VERSION}.tgz
