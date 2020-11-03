#!/usr/bin/env bash

is_installed() {
    cmd micro
}

install() {
    VER=$(latest zyedidia/micro | sed 's/v//')
    URL="https://github.com/zyedidia/micro/releases/download/v$VER/micro-$VER-linux64.tar.gz"
    curl "$URL" | tar xz
    mv "micro-$VER/micro" "$BIN"
}
