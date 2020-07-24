#!/usr/bin/env bash

is_installed() {
    cmd jq
}

install() {
    JQ_VER=$(latest stedolan/jq "jq-$VERSION_RE")
    JQ_URL=https://github.com/stedolan/jq/releases/download/jq-$JQ_VER/jq-linux64
    curl -o "$BIN/jq" "$JQ_URL"
    chmod +x "$BIN/jq"
}
