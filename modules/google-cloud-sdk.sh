#!/usr/bin/env bash

is_installed() {
    which gcloud
}

install() {
    VER=$(latest https://cloud.google.com/sdk/docs/release-notes ">$VERSION_RE \(")
    URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$VER-linux-x86_64.tar.gz
    cd "$LOCAL" || fail "Couldn't cd into $LOCAL"
    curl "$URL" | tar xvz google-cloud-sdk
    ./google-cloud-sdk/install.sh --quiet --usage-reporting false
    PATHRC="${LOCAL/$HOME/\~}/google-cloud-sdk/path.zsh.inc"
    grep -q "$PATHRC" ~/.zshrc || echo "[ -f $PATHRC ] && source $PATHRC" >>~/.zshrc
}
