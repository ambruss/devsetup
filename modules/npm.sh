#!/usr/bin/env bash

is_installed() {
    export NPM_CONFIG_PREFIX=$NODE
    npm ls --global --depth=0 --parseable=true 2>/dev/null\
        | grep "node_modules/" \
        | sed 's|.*node_modules/(.*)|\1|' >npm.list \
        || return 1
    for PACKAGE in "${NPM_PACKAGES[@]}"; do
        grep -q "^$PACKAGE\$" npm.list || return 1
    done
}

install() {
    export NPM_CONFIG_PREFIX=$NODE
    for PACKAGE in "${NPM_PACKAGES[@]}"; do
        npm install --global "$PACKAGE"
    done
}

NPM_PACKAGES=(
    "eslint"
    "fkill"
    "jsonlint"
    "markdownlint-cli"
    "puppeteer"
    "speed-test"
    "standard"
    "tldr"
)
