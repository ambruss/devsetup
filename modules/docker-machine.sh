#!/usr/bin/env bash

is_installed() {
    which docker-machine
}

install() {
    VER=$(latest docker/machine)
    URL=https://github.com/docker/machine/releases/download/$VER/docker-machine-Linux-x86_64
    curl -o "$BIN/docker-machine" "$URL"
    chmod +x "$BIN/docker-machine"
}
