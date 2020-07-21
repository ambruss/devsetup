#!/usr/bin/env bash

is_installed() {
    which spotify
}

install() {
    curl https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt-get update -qq
    sudo apt-get install -qqy spotify-client
}
