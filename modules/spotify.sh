#!/usr/bin/env bash

is_installed() {
    cmd spotify
}

install() {
    echo "The spotify signing key expired - skipping install for now"
    # curl https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add -
    # sudo add-apt-repository "deb http://repository.spotify.com stable non-free"
    # sudo apt-get update -qq
    # sudo apt-get install -qqy spotify-client
}
