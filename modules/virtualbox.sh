#!/usr/bin/env bash

is_installed() {
    which virtualbox
}

install() {
    VBOX_URL=$(curl https://www.virtualbox.org/wiki/Linux_Downloads \
        | grep "All distributions" | grep -o "https://.*run")
    VBOX_EXTPACK_URL=$(curl https://www.virtualbox.org/wiki/Downloads \
        | grep "All supported platforms" | grep -o "https://.*extpack")
    curl -o vbox.run "$VBOX_URL"
    chmod +x vbox.run
    sudo ./vbox.run
    curl -O "$VBOX_EXTPACK_URL"
    sudo VBoxManage extpack install \
        --accept-license=56be48f923303c8cababb0bb4c478284b688ed23f16d775d729b89a2e8e5f9eb \
        --replace Oracle_VM_VirtualBox_Extension_Pack*
}
