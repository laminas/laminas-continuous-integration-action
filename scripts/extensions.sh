#!/bin/bash
# Install and/or enable extensions.
# Usage:
#
#   extensions.sh PHP_VERSION LIST_OF_EXTENSIONS

set -e

STATIC_EXTENSIONS=(sqlsrv swoole)

function match_in_array {
    local NEEDLE="$1"
    local -a ARRAY_SET=("${@:2}")
    local item

    for item in "${ARRAY_SET[@]}";do
        [[ "${item}" =~ ${NEEDLE} ]] && return 0
    done

    return 1
}

function install_packaged_extensions {
    local -a EXTENSIONS=("${@:1}")
    local TO_INSTALL="${EXTENSIONS[*]}"

    echo "Installing packaged extensions: ${TO_INSTALL}"
    apt update
    # shellcheck disable=SC2086,SC2046
    apt install -y ${TO_INSTALL}
}

function enable_static_extension {
    local PHP=$1
    local EXTENSION=$2

    echo "Enabling ${EXTENSION} extension"
    phpenmod -v "${PHP}" -s ALL "${EXTENSION}"
}

function enable_sqlsrv {
    local __result=$1
    local PHP=$2
    local -a EXTENSIONS=("${@:3}")
    local TO_RETURN

    if [[ ! ${PHP} =~ (7.3|7.4|8.0) ]];then
        echo "Skipping enabling of sqlsrv extension; not supported on PHP < 7.3"
    else
        enable_static_extension "${PHP}" sqlsrv
    fi

    TO_RETURN=$(echo "${EXTENSIONS[@]}" | sed -E -e 's/php[0-9.]+-(pdo[_-]){0,1}sqlsrv/ /g' | sed -E -e 's/\s{2,}/ /g')
    eval "$__result='$TO_RETURN'"
}

function enable_swoole {
    local __result=$1
    local PHP=$2
    local -a EXTENSIONS=("${@:3}")
    local TO_RETURN

    if [[ ! ${PHP} =~ (7.3|7.4|8.0) ]];then
        echo "Skipping enabling of swoole extension; not supported on PHP < 7.3"
    else
        enable_static_extension "${PHP}" swoole
    fi

    TO_RETURN=$(echo "${EXTENSIONS[@]}" | sed -E -e 's/php[0-9.]+-swoole/ /g' | sed -E -e 's/\s{2,}/ /g')
    eval "$__result='$TO_RETURN'"
}

PHP=$1
EXTENSIONS=("${@:2}")
declare result ENABLE_FUNC

# Loop through known statically compiled/installed extensions, and enable them.
# Each should update the result variable passed to it with a new list of
# extensions.
for EXTENSION in "${STATIC_EXTENSIONS[@]}";do
    if match_in_array "${EXTENSION}" "${EXTENSIONS[@]}" ; then
        ENABLE_FUNC="enable_${EXTENSION}"
        $ENABLE_FUNC result "${PHP}" "${EXTENSIONS[*]}"

		# Validate that we don't have just whitespace in the list
        if [[ -z "${result// }" ]];then
            EXTENSIONS=()
        else
            EXTENSIONS=("${result}")
        fi
    fi
done

# If by now the extensions list is not empty, install packaged extensions.
if [[ ${#EXTENSIONS[@]} != 0 ]];then
    install_packaged_extensions "${EXTENSIONS[@]}"
fi
