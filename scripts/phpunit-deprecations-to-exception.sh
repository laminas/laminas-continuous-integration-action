#!/bin/bash

if [ -f "/scripts/logging-functions.sh" ]; then
  source /scripts/logging-functions.sh
elif [ -f "scripts/logging-functions.sh" ]; then
  source scripts/logging-functions.sh
else
  echo "Could not find logging-functions.sh"
  exit 1
fi

PHPUNIT_CONFIGURATION_FILE=""

if [ -f "phpunit.xml" ]; then
    PHPUNIT_CONFIGURATION_FILE="phpunit.xml"
elif [ -f "phpunit.xml.dist" ]; then
  PHPUNIT_CONFIGURATION_FILE="phpunit.xml.dist"
else
  warning "Could not detect phpunit configuration. Won't change anything."
  exit 0;
fi

if [ -z "${PHPUNIT_CONFIGURATION_FILE}" ]; then
  error "Could not detect phpunit configuration. Please report this to https://github.com/laminas/laminas-continuous-integration-action/issues"
  exit 1;
fi

warning "Updating ${PHPUNIT_CONFIGURATION_FILE} to enforce convertDeprecationsToExceptions=true."
warning "In case that the project specifies that value itself, this won't update anything."

xmlstarlet ed --inplace --insert '//phpunit[not(@convertDeprecationsToExceptions)]' \
            --type attr --name 'convertDeprecationsToExceptions' --value "true" \
            "${PHPUNIT_CONFIGURATION_FILE}"
