#!/usr/bin/env bash

is_installed() {
    cmd git-crypt
}

install() {
    DIR="$SHARE/git-crypt"
    test -d "$DIR" || clone AGWA/git-crypt "$DIR"
    cdir "$DIR"
    git pull
    make
    make install "PREFIX=$LOCAL"
}
