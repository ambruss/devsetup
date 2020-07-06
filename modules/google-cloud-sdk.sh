#!/usr/bin/env bash

is_installed() {
    which gcloud
}

install() {
    GCLOUD_VER=$(latest https://cloud.google.com/sdk/docs/release-notes ">$VERSION_RE \(")
    GCLOUD_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$GCLOUD_VER-linux-x86_64.tar.gz
    curl "$GCLOUD_URL" | tar xvz google-cloud-sdk
    # TODO noninteractive
    ./google-cloud-sdk/install.sh
}
