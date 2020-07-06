#!/usr/bin/env bash

is_installed() {
    which terraform
}

install() {
    TF_VER=$(latest "https://www.terraform.io/downloads.html terraform/$VERSION_RE")
    TF_URL=https://releases.hashicorp.com/terraform/$TF_VER/terraform_${TF_VER}_linux_amd64.zip
    curl -o terraform.zip "$TF_URL"
    unzip terraform.zip
    mv terraform "$BIN"
}
