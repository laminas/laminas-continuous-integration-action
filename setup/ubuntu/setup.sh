#!/bin/bash

apt update \
    && apt install -y software-properties-common curl \
    && (curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -) \
    && add-apt-repository -y ppa:ondrej/php \
    && add-apt-repository -y https://packages.microsoft.com/ubuntu/20.04/prod \
    && ACCEPT_EULA=Y xargs -a dependencies apt install -y
