#!/bin/bash
# Install and/or enable extensions.
# Usage:
#
#   extensions.sh PHP_VERSION LIST_OF_EXTENSIONS

set -e

SWOOLE_PACKAGE_URL="https://github.com/weierophinney/laminas-ci-swoole-builder/releases/download/0.2.2/php%s-%s.tgz"

function install_extensions {
    local PHP=$1
    local -a EXTENSIONS=()
    for EXTENSION in "${@:2}"; do
      EXTENSIONS+=("$EXTENSION")
    done

    case "$PHP" in
		# Example for handling extensions for different PHP versions:
        # 8.1)
        #     echo "Cannot install extensions for the current PHP version."
        #     echo "Please use \".laminas-ci/pre-run.sh\" to setup specific extensions for PHP $PHP"
        #     echo "Additional details can be found on https://stackoverflow.com/q/8141407"
        #     echo "The following extensions were not installed: ${EXTENSIONS[*]}"
        # ;;
        *)
            install_packaged_extensions "$PHP" "${EXTENSIONS[@]}"
        ;;
    esac
}

function install_swoole_extension {
    local PHP=$1
    local extension=$2
    local package_url
    local package

    # shellcheck disable=SC2059
    package_url=$(printf "${SWOOLE_PACKAGE_URL}" "${PHP}" "${extension}")
    package=$(basename "${package_url}")

    echo "Fetching ${extension} extension package for PHP ${PHP}"
    cd /tmp
    wget "${package_url}"
    cd /
    tar xzf "/tmp/${package}"
    rm -rf "/tmp/${package}"
    phpenmod -v "${PHP}" -s ALL "${extension}"
}

function install_packaged_extensions {
    local PHP=$1
    # shellcheck disable=SC2206
    local -a EXTENSIONS=()
    for EXTENSION in "${@:2}"; do
      EXTENSIONS+=("$EXTENSION")
    done
    local TO_INSTALL=""

    for EXTENSION in "${EXTENSIONS[@]}"; do
        if [[ "${EXTENSION}" =~ openswoole ]]; then
            install_swoole_extension "${PHP}" "openswoole"
        elif [[ "${EXTENSION}" =~ swoole ]]; then
            install_swoole_extension "${PHP}" "swoole"
        else
            # Converting extension name to package name, e.g. php8.0-redis
            TO_INSTALL="${TO_INSTALL}php${PHP}-$EXTENSION "
        fi
    done

    if [ -z "$TO_INSTALL" ]; then
        return;
    fi

    echo "Installing packaged extensions: ${TO_INSTALL}"
    apt update
    # shellcheck disable=SC2086,SC2046
    apt install -y ${TO_INSTALL}
}

function enable_static_extension {
    local PHP=$1
    local EXTENSION=$2

    echo "Enabling \"${EXTENSION}\" extension"
    phpenmod -v "${PHP}" -s ALL "${EXTENSION}"
}

PHP=$1
# shellcheck disable=SC2206
declare -a EXTENSIONS=(${@:2})
# shellcheck disable=SC2196
ENABLED_EXTENSIONS=$(php -m | tr '[:upper:]' '[:lower:]' | egrep -v '^[\[]' | grep -v 'zend opcache')
EXTENSIONS_TO_INSTALL=()

add_extension_to_install() {
    local extension=$1

    # Prevent duplicates
    if [[ ! " ${EXTENSIONS_TO_INSTALL[@]} " =~ " ${extension} " ]]; then
        EXTENSIONS_TO_INSTALL+=("${extension}")
    fi
}

# Loop through known statically compiled/installed extensions, and enable them.
# NOTE: when developing on MacOS, remove the quotes while implementing your changes and re-add the quotes afterwards.
for EXTENSION in "${EXTENSIONS[@]}"; do
    # Check if extension is already enabled
    REGULAR_EXPRESSION=\\b${EXTENSION}\\b
    if [[ "${ENABLED_EXTENSIONS}" =~ $REGULAR_EXPRESSION ]]; then
        echo "Extension \"$EXTENSION\" is already enabled."
        continue;
    fi

    # Check if extension is installable via `phpenmod`
    PATH_TO_EXTENSION_CONFIG="/etc/php/${PHP}/mods-available/${EXTENSION}.ini"

    if [ -e "$PATH_TO_EXTENSION_CONFIG" ]; then
        enable_static_extension "$PHP" "${EXTENSION}"
        continue;
    fi

    if [[ "${EXTENSION}" =~ ^pdo_ ]]; then
        case "${EXTENSION}" in
            "pdo_mysql")
                add_extension_to_install "mysql"
            ;;
            "pdo_sqlite")
                add_extension_to_install "sqlite3"
            ;;
            "pdo_pgsql")
                add_extension_to_install "pgsql"
            ;;
            *)
                echo "Unsupported PDO driver extension \"${EXTENSION}\" cannot is not (yet) supported."
                echo -n "In case the extension is not available already, please consider using .pre-install.sh to install"
                echo " the appropriate extension."
                echo -n "If you think its worth to have the PDO driver extension installed automatically, please create"
                echo " a feature request on github: https://github.com/laminas/laminas-continuous-integration-action/issues"
                continue;
            ;;
        esac

        add_extension_to_install "pdo"
        continue;
    fi

    add_extension_to_install "${EXTENSION}"
done

# If by now the extensions list is not empty, install missing extensions.
if [[ ${#EXTENSIONS_TO_INSTALL[@]} != 0 ]]; then
    install_extensions "$PHP" "${EXTENSIONS_TO_INSTALL[@]}"
fi
