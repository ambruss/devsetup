#!/usr/bin/env bash

is_installed() {
    test -x ~/google-cloud-sdk/bin/gcloud
}

install() {
    export CLOUDSDK_PYTHON=/usr/bin/python3.6
    cdir "$LOCAL"
    curl https://sdk.cloud.google.com | bash -s -- --disable-prompts
}
