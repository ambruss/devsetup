#!/usr/bin/env bash

is_installed() {
    which kubectl
}

install() {
    KUBE_VER=$(latest kubernetes/kubernetes)
    KUBE_URL=https://storage.googleapis.com/kubernetes-release/release/$KUBE_VER/bin/linux/amd64/kubectl
    curl -o "$BIN/kubectl" "$KUBE_URL"
    chmod +x "$BIN/kubectl"
}
