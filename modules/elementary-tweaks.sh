#!/usr/bin/env bash

is_installed() {
    quiet apt show elementary-tweaks
}

install() {
    sudo add-apt-repository -y ppa:philip.scott/elementary-tweaks
    sudo apt-get install -yqq elementary-tweaks
}
