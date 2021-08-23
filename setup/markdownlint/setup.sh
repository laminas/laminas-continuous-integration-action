#!/bin/bash

NODE_ENV=production npm install -g markdownlint-cli2
ln -s /usr/local/bin/markdownlint-cli2 /usr/local/bin/markdownlint
