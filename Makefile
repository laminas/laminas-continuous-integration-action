# Minimum version of PHP supported by this project
PHP_VERSION ?= 8.2
PHP_EXTENSIONS ?= mbstring json xdebug
DOCKER_IMAGE_NAME = laminas/ci-action-dev

# Includes _everything_ supplied by the internal tooling lib
include vendor/laminas/internal-tooling/Makefile
