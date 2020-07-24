#!/usr/bin/env bash

is_installed() {
    cmd helm
}

install() {
    HELM_VER=$(latest helm/helm)
    HELM_URL=https://get.helm.sh/helm-$HELM_VER-linux-amd64.tar.gz
    curl "$HELM_URL" | tar xz
    mv -f linux-amd64/helm "$BIN"
}
