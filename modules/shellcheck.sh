#!/usr/bin/env bash

is_installed() {
    cmd shellcheck
}

install() {
    VER=$(latest koalaman/shellcheck)
    URL=https://github.com/koalaman/shellcheck/releases/download/$VER/shellcheck-$VER.linux.x86_64.tar.xz
    curl "$URL" | tar xJ
    mv -f "shellcheck-$VER/shellcheck" "$BIN"
}
