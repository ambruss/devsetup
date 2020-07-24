#!/usr/bin/env bash

is_installed() {
    cmd google-chrome
}

install() {
    curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg --install google-chrome-stable_current_amd64.deb || sudo apt-get install -fqqy
}
