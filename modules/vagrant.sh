#!/usr/bin/env bash

is_installed() {
    which vagrant
}

install() {
    VER=$(latest hashicorp/vagrant | sed 's/v//')
    URL=https://releases.hashicorp.com/vagrant/$VER/vagrant_${VER}_linux_amd64.zip
    curl -o vagrant.zip "$URL"
    unzip vagrant.zip
    mv vagrant "$BIN"
}
