#!/usr/bin/env bash

is_installed() {
    cmd marktext
}

install() {
    VER=$(latest marktext/marktext)
    URL=https://github.com/marktext/marktext/releases/download/$VER/marktext-x86_64.AppImage
    curl -o "$BIN/marktext" "$URL"
    chmod +x "$BIN/marktext"
}
