#!/usr/bin/env bash

is_installed() {
    which git-crypt
}

install() {
    DIR="$SHARE/git-crypt"
    test -d "$DIR" || clone AGWA/git-crypt "$DIR"
    cd "$DIR" || fail "Couldn't cd into $DIR"
    git pull
    make
    make install "PREFIX=$LOCAL"
}
