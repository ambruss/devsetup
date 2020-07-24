#!/usr/bin/env bash

is_installed() {
    which hadolint
}

install() {
    REPO=hadolint/hadolint
    VER=$(latest $REPO)
    URL=https://github.com/$REPO/releases/download/$VER/hadolint-Linux-x86_64
    curl -o "$BIN/hadolint" "$URL"
    chmod +x "$BIN/hadolint"
}
