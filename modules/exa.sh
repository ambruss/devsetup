#!/usr/bin/env bash

is_installed() {
    cmd exa
}

install() {
    EXA_VER=$(latest ogham/exa)
    EXA_ZIP=exa-linux-x86_64-$EXA_VER.zip
    EXA_URL=https://github.com/ogham/exa/releases/download/$EXA_VER/$EXA_ZIP
    curl -O "$EXA_URL"
    unzip "$EXA_ZIP"
    mv -f bin/exa "$BIN/exa"
}
