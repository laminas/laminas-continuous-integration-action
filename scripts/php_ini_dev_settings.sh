#!/bin/bash

set -e

declare -a SUBSTITUTIONS

SUBSTITUTIONS+=('s/zend.exception_ignore_args ?= ?(On|Off)/zend.exception_ignore_args = Off/')
SUBSTITUTIONS+=('s/zend.exception_string_param_max_len ?= ?[0-9]+/zend.exception_string_param_max_len = 15/')
SUBSTITUTIONS+=('s/error_reporting ?= ?[A-Z_~ &]+/error_reporting = E_ALL/')
SUBSTITUTIONS+=('s/display_errors ?= ?(On|Off)/display_errors = On/')
SUBSTITUTIONS+=('s/display_startup_errors ?= ?(On|Off)/display_startup_errors = On/')
SUBSTITUTIONS+=('s/mysqlnd.collect_memory_statistics ?= ?(On|Off)/mysqlnd.collect_memory_statistics = On/')
SUBSTITUTIONS+=('s/zend.assertions ?= ?(-1|1)/zend.assertions = 1/')
SUBSTITUTIONS+=('s/opcache.huge_code_pages ?= ?(0|1)/opcache.huge_code_pages = 0/')

for PHP_VERSION in 5.6 7.0 7.1 7.2 7.3 7.4 8.0;do
    INI_FILE="/etc/php/${PHP_VERSION}/cli/php.ini"
    for SUBSTITUTION in "${SUBSTITUTIONS[@]}";do
        sed --in-place -E -e "${SUBSTITUTION}" "${INI_FILE}"
    done
done
