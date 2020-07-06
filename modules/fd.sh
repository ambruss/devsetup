#!/usr/bin/env bash

is_installed() {
    which fd
}

install() {
    FD_VER=$(latest sharkdp/fd)
    FD_DIR=fd-$FD_VER-x86_64-unknown-linux-gnu
    FD_URL=https://github.com/sharkdp/fd/releases/download/$FD_VER/$FD_DIR.tar.gz
    curl "$FD_URL" | tar xz
    mv -f "$FD_DIR/fd" "$BIN"
}
