FROM composer:2 AS composer

FROM ubuntu:focal

LABEL "repository"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "homepage"="http://github.com/laminas/laminas-continuous-integration-action"
LABEL "maintainer"="https://github.com/laminas/technical-steering-committee/"

ENV COMPOSER_HOME=/usr/local/share/composer

RUN apt update \
    && apt install -y software-properties-common curl \
    && (curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -) \
    && add-apt-repository -y ppa:ondrej/php \
    && add-apt-repository -y https://packages.microsoft.com/ubuntu/20.04/prod \
    && ACCEPT_EULA=Y apt install -y \
        git \
        jq \
        libxml2-utils \
        libzip-dev \
        npm \
        sudo \
        wget \
        yamllint \
        zip \
        msodbcsql17 \
        php5.6-bz2 \
        php5.6-cli \
        php5.6-curl \
        php5.6-dev \
        php5.6-fileinfo \
        php5.6-intl \
        php5.6-json \
        php5.6-mbstring \
        php5.6-phar \
        php5.6-readline \
        php5.6-sockets \
        php5.6-xml \
        php5.6-xsl \
        php5.6-zip \
        php7.0-cli \
        php7.0-bz2 \
        php7.0-curl \
        php7.0-dev \
        php7.0-fileinfo \
        php7.0-intl \
        php7.0-json \
        php7.0-mbstring \
        php7.0-phar \
        php7.0-readline \
        php7.0-sockets \
        php7.0-xml \
        php7.0-xsl \
        php7.0-zip \
        php7.1-cli \
        php7.1-bz2 \
        php7.1-curl \
        php7.1-dev \
        php7.1-fileinfo \
        php7.1-intl \
        php7.1-json \
        php7.1-mbstring \
        php7.1-phar \
        php7.1-readline \
        php7.1-sockets \
        php7.1-xml \
        php7.1-xsl \
        php7.1-zip \
        php7.2-cli \
        php7.2-bz2 \
        php7.2-curl \
        php7.2-dev \
        php7.2-fileinfo \
        php7.2-intl \
        php7.2-json \
        php7.2-mbstring \
        php7.2-phar \
        php7.2-readline \
        php7.2-sockets \
        php7.2-xml \
        php7.2-xsl \
        php7.2-zip \
        php7.3-cli \
        php7.3-bz2 \
        php7.3-curl \
        php7.3-dev \
        php7.3-fileinfo \
        php7.3-intl \
        php7.3-json \
        php7.3-mbstring \
        php7.3-phar \
        php7.3-readline \
        php7.3-sockets \
        php7.3-xml \
        php7.3-xsl \
        php7.3-zip \
        php7.4-cli \
        php7.4-bz2 \
        php7.4-curl \
        php7.4-dev \
        php7.4-fileinfo \
        php7.4-intl \
        php7.4-json \
        php7.4-mbstring \
        php7.4-phar \
        php7.4-readline \
        php7.4-sockets \
        php7.4-xml \
        php7.4-xsl \
        php7.4-zip \
        php8.0-cli \
        php8.0-bz2 \
        php8.0-curl \
        php8.0-dev \
        php8.0-fileinfo \
        php8.0-intl \
        php8.0-mbstring \
        php8.0-phar \
        php8.0-readline \
        php8.0-sockets \
        php8.0-xml \
        php8.0-xsl \
        php8.0-zip \
    && apt clean \
    && update-alternatives --set php /usr/bin/php7.4 \
    && npm install -g markdownlint-cli2 \
    && ln -s /usr/local/bin/markdownlint-cli2 /usr/local/bin/markdownlint

# Build/install static modules that do not have packages
COPY mods-available /mods-available
COPY mods-install /mods-install
RUN for INSTALLER in /mods-install/*.sh;do ${INSTALLER} ; done

RUN mkdir -p /etc/laminas-ci/problem-matcher \
    && cd /etc/laminas-ci/problem-matcher \
    && wget https://raw.githubusercontent.com/shivammathur/setup-php/master/src/configs/phpunit.json \
    && wget -O markdownlint.json https://raw.githubusercontent.com/xt0rted/markdownlint-problem-matcher/main/.github/problem-matcher.json

COPY etc/markdownlint.json /etc/laminas-ci/markdownlint.json

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN mkdir -p /usr/local/share/composer \
    && composer global require staabm/annotate-pull-request-from-checkstyle \
    && ln -s /usr/local/share/composer/vendor/bin/cs2pr /usr/local/bin/cs2pr

COPY scripts /scripts
RUN /scripts/php_ini_dev_settings.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN useradd -ms /bin/bash testuser

ENTRYPOINT ["entrypoint.sh"]
