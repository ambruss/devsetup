#!/usr/bin/env bash

is_installed() {
    cmd pandoc
}

install() {
    VER=$(latest jgm/pandoc)
    DEB=pandoc-$VER-1-amd64.deb
    URL=https://github.com/jgm/pandoc/releases/download/$VER/$DEB
    curl -O "$URL"
    sudo dpkg --install "$DEB" || sudo apt-get install -fqqy
    # TODO first-run
}
