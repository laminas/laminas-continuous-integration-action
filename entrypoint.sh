#!/bin/bash

set -e
set -o pipefail

function help {
    echo "$0 <JSON>"
    echo ""
    echo "Run a QA JOB as specified in a JSON object."
    echo "The JSON should include each of the following elements:"
    echo " - command:                         command to run"
    echo " - php:                             the PHP version to use"
    echo " - extensions:                      a list of additional extensions to enable"
    echo " - ini:                             a list of php.ini directives"
    echo " - dependencies:                    the dependency set to run against (lowest, latest, locked)"
    echo " - ignore_php_platform_requirement: flag to enable/disable the PHP platform requirement when executing composer \`install\` or \`update\`"
    echo " - additional_composer_arguments:   a list of composer arguments to be added when \`install\` or \`update\` is called."
    echo " - before_script:                   a list of commands to run before the real command"
    echo " - after_script:                    a list of commands to run after the real command"
    echo ""
}

function checkout {
    local REF=
    local LOCAL_BRANCH=
    local LOCAL_BRANCH_NAME=

    if [[ ! $GITHUB_EVENT_NAME || ! $GITHUB_REPOSITORY || ! $GITHUB_REF ]];then
        return
    fi

    LOCAL_BRANCH_NAME=$GITHUB_HEAD_REF

    case $GITHUB_EVENT_NAME in
        pull_request)
            REF=$GITHUB_REF
            LOCAL_BRANCH=$GITHUB_HEAD_REF
            BASE_BRANCH=$GITHUB_BASE_REF

            if [[ ! $LOCAL_BRANCH || ! $BASE_BRANCH ]]; then
                echo "Missing head or base ref env variables; aborting"
                exit 1
            fi

            LOCAL_BRANCH_NAME=pull/${LOCAL_BRANCH_NAME}
            ;;
        push)
            REF=${GITHUB_REF/refs\/heads\//}
            LOCAL_BRANCH=${REF}
            ;;
        tag)
            REF=${GITHUB_REF/refs\/tags\//}
            LOCAL_BRANCH=${REF}
            ;;
        *)
            echo "Unable to handle events of type $GITHUB_EVENT_NAME; aborting"
            exit 1
    esac

    if [ -d ".git" ];then
        echo "Updating and fetching from canonical repository"
        if [[ $(git remote) =~ origin ]];then
            git remote remove origin
        fi
        git remote add origin https://github.com/"${GITHUB_REPOSITORY}"
        git fetch origin
    else
        echo "Cloning repository"
        git clone https://github.com/"${GITHUB_REPOSITORY}" .
    fi

    if [[ "$REF" == "$LOCAL_BRANCH" ]];then
        echo "Checking out ref ${REF}"
        git checkout "$REF"
    else
        echo "Checking out branch ${BASE_BRANCH}"
        git checkout "${BASE_BRANCH}"
        echo "Fetching ref ${REF}"
        git fetch origin "${REF}":"${LOCAL_BRANCH_NAME}"
        echo "Checking out target ref to ${LOCAL_BRANCH_NAME}"
        git checkout "${LOCAL_BRANCH_NAME}"
    fi
}

function composer_install_dependencies {
    local DEPS=$1
    local IGNORE_PHP_PLATFORM_REQUIREMENT=$2
    local ADDITIONAL_COMPOSER_ARGUMENTS=$3
    local COMPOSER_ARGS="--ansi --no-interaction --no-progress --prefer-dist ${ADDITIONAL_COMPOSER_ARGUMENTS}"
    if [[ "${IGNORE_PHP_PLATFORM_REQUIREMENT}" == "true" ]];then
        COMPOSER_ARGS="${COMPOSER_ARGS} --ignore-platform-req=php"
    fi


    case $DEPS in
        lowest)
            echo "Installing lowest supported dependencies via Composer"
            # Disable platform.php, if set
            composer config --unset platform.php
            # shellcheck disable=SC2086
            composer update ${COMPOSER_ARGS} --prefer-lowest
            ;;
        latest)
            echo "Installing latest supported dependencies via Composer"
            # Disable platform.php, if set
            composer config --unset platform.php
            # shellcheck disable=SC2086
            composer update ${COMPOSER_ARGS}
            ;;
        *)
            echo "Installing dependencies as specified in lockfile via Composer"
            # shellcheck disable=SC2086
            composer install ${COMPOSER_ARGS}
            ;;
    esac

    composer show
}

if [ $# -ne 1 ]; then
    echo "Missing or extra arguments; expects a single JSON string with job information"
    echo ""
    help
    exit 1
fi

JOB=$1
echo "Received job: ${JOB}"

COMMAND=$(echo "${JOB}" | jq -r '.command // ""')

if [[ "${COMMAND}" == "" ]];then
    echo "Command is empty; nothing to run"
    exit 0
fi

PHP=$(echo "${JOB}" | jq -r '.php // ""')
if [[ "${PHP}" == "" ]];then
    echo "Missing PHP version in job"
    help
    exit 1
fi

declare -a BEFORE_SCRIPT=()
readarray -t BEFORE_SCRIPT="$(echo "${JOB}" | jq -rc '(.before_script // [])[]' )"

declare -a AFTER_SCRIPT=()
readarray -t AFTER_SCRIPT="$(echo "${JOB}" | jq -rc '(.after_script // [])[]' )"


echo "Marking PHP ${PHP} as configured default"
update-alternatives --quiet --set php "/usr/bin/php${PHP}"
update-alternatives --quiet --set php-config "/usr/bin/php-config${PHP}"
update-alternatives --quiet --set phpize "/usr/bin/phpize${PHP}"
update-alternatives --quiet --set phpdbg "/usr/bin/phpdbg${PHP}"

# Marks the working directory as safe for the current user prior to checkout
git config --global --add safe.directory '*'
checkout

# Is there a pre-install script available?
if [ -x ".laminas-ci/pre-install.sh" ];then
    echo "Executing pre-install commands from .laminas-ci/pre-install.sh"
    ./.laminas-ci/pre-install.sh testuser "${PWD}" "${JOB}"
fi

EXTENSIONS=$(echo "${JOB}" | jq -r ".extensions // [] | join(\" \")")
INI=$(echo "${JOB}" | jq -r '.ini // [] | join("\n")')
DEPS=$(echo "${JOB}" | jq -r '.dependencies // "locked"')
IGNORE_PLATFORM_REQS_ON_8=$(echo "${JOB}" | jq -r 'if has("ignore_platform_reqs_8") | not then "yes" elif .ignore_platform_reqs_8 then "yes" else "no" end')
IGNORE_PHP_PLATFORM_REQUIREMENT=$(echo "${JOB}" | jq -r '.ignore_php_platform_requirement')
ADDITIONAL_COMPOSER_ARGUMENTS=$(echo "${JOB}" | jq -r '.additional_composer_arguments // [] | join("\n")')

# Old matrix generation
if [ "${IGNORE_PHP_PLATFORM_REQUIREMENT}" == "null" ]; then
    IGNORE_PHP_PLATFORM_REQUIREMENT="false"

    # Provide BC compatibility
    if [ "${IGNORE_PLATFORM_REQS_ON_8}" == "yes" ] && [[ "${PHP}" =~ ^8 ]]; then
        IGNORE_PHP_PLATFORM_REQUIREMENT="true"
    fi
fi

if [[ "${EXTENSIONS}" != "" ]];then
    /scripts/extensions.sh "${PHP}" "${EXTENSIONS}"
fi

if [[ "${INI}" != "" ]];then
    echo "Installing php.ini settings"
    echo "$INI" > "/etc/php/${PHP}/cli/conf.d/99-settings.ini"
    echo "$INI" > "/etc/php/${PHP}/phpdbg/conf.d/99-settings.ini"
fi

echo "PHP version: $(php --version)"
echo "Installed extensions:"
/usr/local/bin/php-extensions-with-version.php

# If a token is present, tell Composer about it so we can avoid rate limits
if [[ "${GITHUB_TOKEN}" != "" ]];then
    composer config --global github-oauth.github.com "${GITHUB_TOKEN}"
fi

composer_install_dependencies "${DEPS}" "${IGNORE_PHP_PLATFORM_REQUIREMENT}" "${ADDITIONAL_COMPOSER_ARGUMENTS}"

if [[ "${COMMAND}" =~ phpunit ]];then
    echo "Setting up PHPUnit problem matcher"
    cp /etc/laminas-ci/problem-matcher/phpunit.json "$(pwd)/phpunit.json"
    echo "::add-matcher::phpunit.json"
fi

if [[ "${COMMAND}" =~ markdownlint ]];then
    echo "Setting up markdownlint problem matcher"
    cp /etc/laminas-ci/problem-matcher/markdownlint.json "$(pwd)/markdownlint-matcher.json"
    echo "::add-matcher::markdownlint-matcher.json"
    if [ ! -f ".markdownlint.json" ];then
        echo "Installing markdownlint configuration"
        cp /etc/laminas-ci/markdownlint.json .markdownlint.json
    fi
fi

chown -R testuser .

# Is there a pre-run script available?
if [ -x ".laminas-ci/pre-run.sh" ];then
    echo "Executing pre-run commands from .laminas-ci/pre-run.sh"
    ./.laminas-ci/pre-run.sh testuser "${PWD}" "${JOB}"
fi

for BEFORE_SCRIPT_COMMAND in "${BEFORE_SCRIPT[@]}"; do
  echo "Running before_script: ${BEFORE_SCRIPT_COMMAND}"
  sudo --preserve-env --set-home -u testuser /bin/bash -c "${BEFORE_SCRIPT_COMMAND}"
done

# Disable exit-on-non-zero flag so we can run post-commands
set +e

echo "Running ${COMMAND}"
sudo --preserve-env --set-home -u testuser /bin/bash -c "${COMMAND}"
STATUS=$?

set -e

# Is there a post-run script available?
if [ -x ".laminas-ci/post-run.sh" ];then
    echo "Executing post-run commands from .laminas-ci/post-run.sh"
    ./.laminas-ci/post-run.sh "${STATUS}" testuser "${PWD}" "${JOB}"
fi

for AFTER_SCRIPT_COMMAND in "${AFTER_SCRIPT[@]}"; do
  echo "Running before_script: ${AFTER_SCRIPT_COMMAND}"
  sudo --preserve-env --set-home -u testuser /bin/bash -c "${AFTER_SCRIPT_COMMAND}"
done

exit ${STATUS}
