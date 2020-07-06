#!/usr/bin/env bash

is_installed() {
    which docker
}

install() {
    curl https://get.docker.com | env -i sh
    sudo usermod -aG docker "$(id -un)"
}
