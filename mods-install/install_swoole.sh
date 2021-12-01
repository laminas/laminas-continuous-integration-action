#!/bin/bash

set -e

SWOOLE_PACKAGE_URL=https://uploads.mwop.net/laminas-ci/swoole-4.8.2-openswoole-4.8.0.tgz
SWOOLE_PACKAGE=$(basename "${SWOOLE_PACKAGE_URL}")

# Download the pre-built extensions
cd /tmp
wget "${SWOOLE_PACKAGE_URL}"
cd /
tar xzf "/tmp/${SWOOLE_PACKAGE}"

# Cleanup
rm -rf "/tmp/${SWOOLE_PACKAGE}"
