#!/usr/bin/env bash

is_installed() {
    cmd miktexsetup
}

install() {
    sudo apt-add-repository "deb http://miktex.org/download/ubuntu bionic universe"
    sudo apt-get update -qq
    sudo apt-get install -qqy miktex
    miktexsetup --user-link-target-directory="$BIN" finish
    initexmf --set-config-value "[MPM]AutoInstall=1"
}
