#!/usr/bin/env bash

is_installed() {
    cmd docker
}

install() {
    curl https://get.docker.com | env -i sh
    sudo usermod -aG docker "$(id -un)"
}
