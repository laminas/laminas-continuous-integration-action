#!/bin/bash

set -e

function help {
    echo "$0 <JSON>"
    echo ""
    echo "Run a QA JOB as specified in a JSON object."
    echo "The JSON should include each of the following elements:"
    echo " - command:       command to run"
    echo " - php:           the PHP version to use"
    echo " - extensions:    a list of additional extensions to enable"
    echo " - ini:           a list of php.ini directives"
    echo " - dependencies:  the dependency set to run against (lowest, latest, locked)"
    echo ""
}

function checkout {
    local REF=
    local LOCAL_BRANCH=

    if [[ ! $GITHUB_EVENT_NAME || ! $GITHUB_REPOSITORY || ! $GITHUB_REF ]];then
        return
    fi

    case $GITHUB_EVENT_NAME in
        pull_request)
            REF=$GITHUB_REF
            LOCAL_BRANCH=$GITHUB_HEAD_REF
            BASE_BRANCH=$GITHUB_BASE_REF

            if [[ ! $LOCAL_BRANCH || ! $BASE_BRANCH ]]; then
                echo "Missing head or base ref env variables; aborting"
                exit 1
            fi
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
        git checkout $REF
    else
        echo "Checking out branch ${BASE_BRANCH}"
        git checkout ${BASE_BRANCH}
        echo "Fetching ref ${REF}"
        git fetch origin $REF:${GITHUB_HEAD_REF}
        echo "Checking out to ${GITHUB_HEAD_REF}"
        git checkout $GITHUB_HEAD_REF
    fi
}

function composer_install {
    local DEPS=$1
    local PHP=$2
    local COMPOSER_ARGS="--ansi --no-interaction --no-progress --prefer-dist"
    if [[ "${PHP}" =~ ^8. ]];then
        # TODO: Remove this when it's not an issue, and/or provide a config
        # option to disable the behavior.
        COMPOSER_ARGS="${COMPOSER_ARGS} --ignore-platform-req=php"
    fi

    case $DEPS in
        lowest)
            echo "Installing lowest supported dependencies via Composer"
            composer update ${COMPOSER_ARGS} --prefer-lowest
            ;;
        latest)
            echo "Installing latest supported dependencies via Composer"
            composer update ${COMPOSER_ARGS}
            ;;
        *)
            echo "Installing dependencies as specified in lockfile via Composer"
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

COMMAND=$(echo "${JOB}" | jq -r '.command')
if [[ "${COMMAND}" == "" ]];then
    echo "Missing command in job; nothing to run"
    help
    exit 1
fi

PHP=$(echo "${JOB}" | jq -r '.php')
if [[ "${COMMAND}" == "" ]];then
    echo "Missing PHP version in job"
    help
    exit 1
fi

EXTENSIONS=$(echo "${JOB}" | jq -r ".extensions | map(\"php${PHP}-\"+.) | join(\" \")")
INI=$(echo "${JOB}" | jq -r '.ini | join("\n")')
DEPS=$(echo "${JOB}" | jq -r '.dependencies')

if [[ "${EXTENSIONS}" != "" ]];then
	ENABLE_SQLSRV=false
	if [[ "${EXTENSIONS}" =~ sqlsrv ]];then
		if [[ ! ${PHP} =~ (7.3|7.4|8.0) ]];then
			echo "Skipping enabling of sqlsrv extensions; not supported on PHP < 7.3"
		else
			ENABLE_SQLSRV=true
		fi
		EXTENSIONS=$(echo ${EXTENSIONS} | sed -E -e 's/php[0-9.]+-(pdo[_-]){0,1}sqlsrv/ /g' | sed -E -e 's/\s{2,}/ /g')
	fi

    echo "Installing extensions: ${EXTENSIONS}"
    apt update
    apt install -y ${EXTENSIONS}

	if [[ "${ENABLE_SQLSRV}" == "true" ]];then
		echo "Enabling sqlsrv extensions"
		phpenmod -v ${PHP} -s ALL sqlsrv
	fi
fi

if [[ "${INI}" != "" ]];then
    echo "Installing php.ini settings"
    echo $INI > /etc/php/${PHP}/cli/conf.d/99-settings.ini
fi

echo "Marking PHP ${PHP} as configured default"
update-alternatives --set php /usr/bin/php${PHP}

echo "PHP version: $(php --version)"
echo "Installed extensions:"
php -m

checkout

composer_install "${DEPS}" "${PHP}"

if [[ "${COMMAND}" =~ phpunit ]];then
    echo "Setting up PHPUnit problem matcher"
    cp /etc/laminas-ci/problem-matcher/phpunit.json $(pwd)/phpunit.json
    echo "::add-matcher::phpunit.json"
fi

if [[ "${COMMAND}" =~ markdownlint ]];then
    echo "Setting up markdownlint problem matcher"
    cp /etc/laminas-ci/problem-matcher/markdownlint.json $(pwd)/markdownlint-matcher.json
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

# Disable exit-on-non-zero flag so we can run post-commands
set +e

echo "Running ${COMMAND}"
sudo -u testuser /bin/bash -c "${COMMAND}"
STATUS=$?

set -e

# Is there a post-run script available?
if [ -x ".laminas-ci/post-run.sh" ];then
    echo "Executing post-run commands from .laminas-ci/post-run.sh"
    ./.laminas-ci/post-run.sh "${STATUS}" testuser "${PWD}" "${JOB}"
fi

exit ${STATUS}
