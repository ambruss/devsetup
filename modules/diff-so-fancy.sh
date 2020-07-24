#!/usr/bin/env bash

is_installed() {
    cmd diff-so-fancy
}

install() {
    URL=https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
    curl -o "$BIN/diff-so-fancy" "$URL"
    chmod +x "$BIN/diff-so-fancy"
}
