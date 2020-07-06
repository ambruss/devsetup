#!/usr/bin/env bash

is_installed() {
    which exa
}

install() {
    EXA_VER=$(latest ogham/exa)
    EXA_BIN=exa-linux-x86_64
    EXA_ZIP=$EXA_BIN-${EXA_VER/v/}.zip
    EXA_URL=https://github.com/ogham/exa/releases/download/$EXA_VER/$EXA_ZIP
    curl -O "$EXA_URL"
    unzip "$EXA_ZIP"
    mv -f "$EXA_BIN" "$BIN/exa"
}
