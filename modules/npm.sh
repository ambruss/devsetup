#!/usr/bin/env bash

is_installed() {
    OLD=$(npm ls --global --depth=0 --parseable=true 2>/dev/null \
        | grep "node_modules/" \
        | sed 's|.*node_modules/(.*)|\1|' \
        | sort)
    NEW=$(comm -23 <(printf "%s\n" "${NPM_PACKAGES[@]}" | sort) <(echo "$OLD"))
    test -z "$NEW" || return 1
}

install() {
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
