# Aliasing base image, so we can change just this, when needing to upgrade or pull base layers
FROM ubuntu:20.04 AS base-distro


FROM base-distro AS install-markdownlint

# Install system dependencies first - these don't change much
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && apt install -y --no-install-recommends npm \
    && apt clean

COPY setup/markdownlint/package.json \
    setup/markdownlint/package-lock.json \
    setup/markdownlint/problem-matcher.json \
    /markdownlint/

COPY setup/markdownlint/dummy-ok-markdown-test-file.md \
    setup/markdownlint/dummy-ko-markdown-test-file.md \
    /test-files/

# Markdownlint
RUN cd /markdownlint \
    && npm ci \
    # Smoke-testing the installation, just making sure it works as expected - should pass first file, fail on second
    && node_modules/.bin/markdownlint-cli2 /test-files/dummy-ok-markdown-test-file.md \
    && if node_modules/.bin/markdownlint-cli2 /test-files/dummy-ko-markdown-test-file.md; then exit 1; else exit 0; fi


FROM base-distro

LABEL "repository"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "homepage"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "maintainer"="https://github.com/laminas/technical-steering-committee/"

ENV COMPOSER_HOME=/usr/local/share/composer
ENV DEBIAN_FRONTEND=noninteractive

COPY setup /setup
# Base setup
RUN cd /setup/ubuntu && bash setup.sh

# PHP
RUN cd /setup/php/5.6 && bash setup.sh
RUN cd /setup/php/7.0 && bash setup.sh
RUN cd /setup/php/7.1 && bash setup.sh
RUN cd /setup/php/7.2 && bash setup.sh
RUN cd /setup/php/7.3 && bash setup.sh
RUN cd /setup/php/7.4 && bash setup.sh
RUN cd /setup/php/8.0 && bash setup.sh
RUN cd /setup/php/8.1 && bash setup.sh

# Set default PHP version
RUN update-alternatives --set php /usr/bin/php7.4 \
    && update-alternatives --set phpize /usr/bin/phpize7.4 \
    && update-alternatives --set php-config /usr/bin/php-config7.4

# Cleanup
RUN rm -rf /setup \
    && apt clean

# Build/install static modules that do not have packages
COPY mods-available /mods-available
COPY mods-install /mods-install
RUN for INSTALLER in /mods-install/*.sh;do ${INSTALLER} ; done

RUN mkdir -p /etc/laminas-ci/problem-matcher \
    && cd /etc/laminas-ci/problem-matcher \
    && wget https://raw.githubusercontent.com/shivammathur/setup-php/master/src/configs/pm/phpunit.json

COPY etc/markdownlint.json /etc/laminas-ci/markdownlint.json

COPY --from=composer:2.2.4 /usr/bin/composer /usr/bin/composer

RUN mkdir -p /usr/local/share/composer \
    && composer global require staabm/annotate-pull-request-from-checkstyle \
    && ln -s /usr/local/share/composer/vendor/bin/cs2pr /usr/local/bin/cs2pr

COPY scripts /scripts
RUN chmod a+x /scripts/*

RUN /scripts/php_ini_dev_settings.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY php-extensions-with-version.php /usr/local/bin/php-extensions-with-version.php
RUN chmod +x /usr/local/bin/php-extensions-with-version.php

# Copy Markdownlint installation to this stage
COPY --from=install-markdownlint /markdownlint /markdownlint
RUN ln -s /markdownlint/node_modules/.bin/markdownlint-cli2 /usr/local/bin/markdownlint

# We use https://github.com/xt0rted/markdownlint-problem-matcher/blob/caf6b376527f8a8ac3b8ed6746989e51a6e560c8/.github/problem-matcher.json
# to match the output of Markdownlint to GitHub Actions annotations (https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-a-warning-message)
COPY setup/markdownlint/markdownlint.json /etc/laminas-ci/problem-matcher

RUN useradd -ms /bin/bash testuser

ENTRYPOINT ["entrypoint.sh"]
