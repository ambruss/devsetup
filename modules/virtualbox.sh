#!/usr/bin/env bash

is_installed() {
    cmd virtualbox
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
    tar -xf Oracle_VM_VirtualBox_Extension_Pack* ./ExtPack-license.txt
    sudo VBoxManage extpack install \
        --accept-license="$(sha256sum ExtPack-license.txt | cut -d" " -f1)" \
        --replace Oracle_VM_VirtualBox_Extension_Pack*
}
