# Aliasing base images, so we can change just this, when needing to upgrade or pull base layers
FROM ubuntu:20.04 AS base-distro
FROM composer:2.3.9 AS composer


FROM base-distro AS install-markdownlint

# Install system dependencies first - these don't change much
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && apt install -y --no-install-recommends \
        npm \
    && apt clean

COPY setup/markdownlint/package.json \
    setup/markdownlint/package-lock.json \
    setup/markdownlint/markdownlint.json \
    /markdownlint/

COPY setup/markdownlint/dummy-ok-markdown-test-file.md \
    setup/markdownlint/dummy-ko-markdown-test-file.md \
    /test-files/

RUN cd /markdownlint \
    && npm ci \
    # Smoke-testing the installation, just making sure it works as expected - should pass first file, fail on second
    && node_modules/.bin/markdownlint-cli2 /test-files/dummy-ok-markdown-test-file.md \
    && if node_modules/.bin/markdownlint-cli2 /test-files/dummy-ko-markdown-test-file.md; then exit 1; else exit 0; fi


FROM composer AS staabm-annotate-pull-request-from-checkstyle

COPY setup/staabm-annotate-pull-request-from-checkstyle/composer.json \
    setup/staabm-annotate-pull-request-from-checkstyle/composer.lock \
    /staabm-annotate-pull-request-from-checkstyle/

RUN cd /staabm-annotate-pull-request-from-checkstyle \
    && composer install \
        --no-dev \
        --classmap-authoritative


FROM base-distro

LABEL "repository"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "homepage"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "maintainer"="https://github.com/laminas/technical-steering-committee/"

ENV COMPOSER_HOME=/usr/local/share/composer \
    DEBIAN_FRONTEND=noninteractive \
    ACCEPT_EULA=Y

# This may look a bit long, but it's just a big `apt install` section, followed by a cleanup,
# so that we get a single compact layer, with not too many layer overwrites.
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
      curl \
      gpg-agent \
      software-properties-common \
    && (curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -) \
    && add-apt-repository -y ppa:ondrej/php \
    && add-apt-repository -y https://packages.microsoft.com/ubuntu/20.04/prod \
    && apt install -y --no-install-recommends \
        # Base dependencies
        git \
        jq \
        libxml2-utils \
        libzip-dev \
        nodejs \
        sudo \
        wget \
        yamllint \
        zip \
        msodbcsql17 \
        \
        php5.6-bz2 \
        php5.6-cli \
        php5.6-curl \
        php5.6-dev \
        php5.6-fileinfo \
        php5.6-intl \
        php5.6-json \
        php5.6-mbstring \
        php5.6-phar \
        php5.6-phpdbg \
        php5.6-readline \
        php5.6-sockets \
        php5.6-xml \
        php5.6-xsl \
        php5.6-zip \
        \
        php7.0-cli \
        php7.0-bz2 \
        php7.0-curl \
        php7.0-dev \
        php7.0-fileinfo \
        php7.0-intl \
        php7.0-json \
        php7.0-mbstring \
        php7.0-phar \
        php7.0-phpdbg \
        php7.0-readline \
        php7.0-sockets \
        php7.0-xml \
        php7.0-xsl \
        php7.0-zip \
        \
        php7.1-cli \
        php7.1-bz2 \
        php7.1-curl \
        php7.1-dev \
        php7.1-fileinfo \
        php7.1-intl \
        php7.1-json \
        php7.1-mbstring \
        php7.1-phar \
        php7.1-phpdbg \
        php7.1-readline \
        php7.1-sockets \
        php7.1-xml \
        php7.1-xsl \
        php7.1-zip \
        \
        php7.2-cli \
        php7.2-bz2 \
        php7.2-curl \
        php7.2-dev \
        php7.2-fileinfo \
        php7.2-intl \
        php7.2-json \
        php7.2-mbstring \
        php7.2-phar \
        php7.2-phpdbg \
        php7.2-readline \
        php7.2-sockets \
        php7.2-xml \
        php7.2-xsl \
        php7.2-zip \
        \
        php7.3-cli \
        php7.3-bz2 \
        php7.3-curl \
        php7.3-dev \
        php7.3-fileinfo \
        php7.3-intl \
        php7.3-json \
        php7.3-mbstring \
        php7.3-phar \
        php7.3-phpdbg \
        php7.3-readline \
        php7.3-sockets \
        php7.3-xml \
        php7.3-xsl \
        php7.3-zip \
        \
        php7.4-cli \
        php7.4-bz2 \
        php7.4-curl \
        php7.4-dev \
        php7.4-fileinfo \
        php7.4-intl \
        php7.4-json \
        php7.4-mbstring \
        php7.4-phar \
        php7.4-phpdbg \
        php7.4-readline \
        php7.4-sockets \
        php7.4-xml \
        php7.4-xsl \
        php7.4-zip \
        \
        php8.0-cli \
        php8.0-bz2 \
        php8.0-curl \
        php8.0-dev \
        php8.0-fileinfo \
        php8.0-intl \
        php8.0-mbstring \
        php8.0-phar \
        php8.0-phpdbg \
        php8.0-readline \
        php8.0-sockets \
        php8.0-xml \
        php8.0-xsl \
        php8.0-zip \
        \
        php8.1-cli \
        php8.1-bz2 \
        php8.1-curl \
        php8.1-dev \
        php8.1-fileinfo \
        php8.1-intl \
        php8.1-mbstring \
        php8.1-phar \
        php8.1-phpdbg \
        php8.1-readline \
        php8.1-sockets \
        php8.1-xml \
        php8.1-xsl \
        php8.1-zip \
    # Set default PHP version
    && update-alternatives --set php /usr/bin/php7.4 \
    && update-alternatives --set phpize /usr/bin/phpize7.4 \
    && update-alternatives --set php-config /usr/bin/php-config7.4 \
    && apt autoremove -y \
    && apt clean

# Build/install static modules that do not have packages
COPY mods-available /mods-available
COPY mods-install /mods-install
RUN set -e; for INSTALLER in /mods-install/*.sh; do ${INSTALLER} ; done

COPY scripts /scripts
RUN chmod a+x /scripts/*

RUN /scripts/php_ini_dev_settings.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY php-extensions-with-version.php /usr/local/bin/php-extensions-with-version.php
RUN chmod +x /usr/local/bin/php-extensions-with-version.php

# Copy Markdownlint installation to this stage
COPY --from=install-markdownlint /markdownlint /markdownlint
RUN ln -s /markdownlint/node_modules/.bin/markdownlint-cli2 /usr/local/bin/markdownlint
COPY --from=install-markdownlint /markdownlint/markdownlint.json /etc/laminas-ci/markdownlint.json


# Copy staabm/annotate-pull-request-from-checkstyle to this stage
COPY --from=staabm-annotate-pull-request-from-checkstyle /staabm-annotate-pull-request-from-checkstyle /staabm-annotate-pull-request-from-checkstyle
RUN ln -s /staabm-annotate-pull-request-from-checkstyle/vendor/bin/cs2pr /usr/local/bin/cs2pr


# Add composer binary to the image
COPY --from=composer /usr/bin/composer /usr/bin/composer


# We use https://github.com/xt0rted/markdownlint-problem-matcher/blob/caf6b376527f8a8ac3b8ed6746989e51a6e560c8/.github/problem-matcher.json
# and https://github.com/shivammathur/setup-php/blob/57db6baebbe30a3126c7a03aa0e3267fa7872d96/src/configs/pm/phpunit.json
# to match the output of Markdownlint and PHPUnit to GitHub Actions
# annotations (https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-a-warning-message)
COPY setup/markdownlint/problem-matcher.json /etc/laminas-ci/problem-matcher/markdownlint.json
COPY setup/phpunit/problem-matcher.json /etc/laminas-ci/problem-matcher/phpunit.json


RUN useradd -ms /bin/bash testuser

ENTRYPOINT ["entrypoint.sh"]
