#!/bin/bash
# Install and/or enable extensions.
# Usage:
#
#   extensions.sh PHP_VERSION LIST_OF_EXTENSIONS

set -e

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

function install_packaged_extensions {
    local PHP=$1
    # shellcheck disable=SC2206
    local -a EXTENSIONS=()
    for EXTENSION in "${@:2}"; do
      EXTENSIONS+=("$EXTENSION")
    done
    local TO_INSTALL=""

    for EXTENSION in "${EXTENSIONS[@]}"; do
        # Converting extension name to package name, e.g. php8.0-redis
        TO_INSTALL="${TO_INSTALL}php${PHP}-$EXTENSION "
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

    EXTENSIONS_TO_INSTALL+=("$EXTENSION")
done

# If by now the extensions list is not empty, install missing extensions.
if [[ ${#EXTENSIONS_TO_INSTALL[@]} != 0 ]]; then
    install_extensions "$PHP" "${EXTENSIONS_TO_INSTALL[@]}"
fi
