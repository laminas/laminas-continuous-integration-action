#!/bin/bash

function warning() {
    MESSAGE="$*";
    write "\e[33m$MESSAGE"
}

function error() {
    MESSAGE="$*";
    >&2 write "\e[31m$MESSAGE"
}

function log() {
    MESSAGE="$*";
    write "\e[39m$MESSAGE"
}

function write() {
    MESSAGE="$*";
    test -t 1 && echo -e "$MESSAGE\e[39m"
}

function info() {
    MESSAGE="$*";
    >&2 write "\e[32m$MESSAGE";
}
