#!/usr/bin/env bash

is_installed() {
    cmd onlyoffice-desktopeditors
}

install() {
    URL=https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
    curl -O "$URL"
    sudo dpkg --install onlyoffice-desktopeditors_amd64.deb || sudo apt-get install -fqqy
}
