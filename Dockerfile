FROM composer:2.2.3 AS composer

FROM ubuntu:focal

LABEL "repository"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "homepage"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "maintainer"="https://github.com/laminas/technical-steering-committee/"

ENV COMPOSER_HOME=/usr/local/share/composer
ENV DEBIAN_FRONTEND=noninteractive

COPY setup /setup
# Base setup
RUN cd /setup/ubuntu && bash setup.sh

# Markdownlint
RUN cd /setup/markdownlint && bash setup.sh

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
    && wget https://raw.githubusercontent.com/shivammathur/setup-php/master/src/configs/pm/phpunit.json \
    && wget -O markdownlint.json https://raw.githubusercontent.com/xt0rted/markdownlint-problem-matcher/main/.github/problem-matcher.json

COPY etc/markdownlint.json /etc/laminas-ci/markdownlint.json

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN mkdir -p /usr/local/share/composer \
    && composer global require staabm/annotate-pull-request-from-checkstyle \
    && ln -s /usr/local/share/composer/vendor/bin/cs2pr /usr/local/bin/cs2pr

COPY scripts /scripts
RUN chmod a+x /scripts/*

RUN /scripts/php_ini_dev_settings.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY php-extensions-with-version.php /usr/local/bin/php-extensions-with-version.php
RUN chmod +x /usr/local/bin/php-extensions-with-version.php

RUN useradd -ms /bin/bash testuser

ENTRYPOINT ["entrypoint.sh"]
