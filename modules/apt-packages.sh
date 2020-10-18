#!/usr/bin/env bash

is_installed() {
    apt list --installed 2>/dev/null | sed -E 's|([^/]+)/.*|\1|' >apt.list
    for PACKAGE in "${APT_PACKAGES[@]}"; do
        grep -q "^$PACKAGE\$" apt.list || return 1
    done
    return 0
}

install() {
    if ! cmd apt-add-repository; then
        sudo apt-get update -qq
        sudo apt-get install -qqy software-properties-common
    fi
    sudo apt-add-repository -y ppa:philip.scott/elementary-tweaks
    sudo apt-add-repository -y ppa:yunnxx/elementary
    sudo apt-get update -qq
    sudo apt-get install -qqy "${APT_PACKAGES[@]}"
    sudo sh -c "printf '[User]\nSystemAccount=true\n' > /var/lib/AccountsService/users/libvirt-qemu"
    sudo rm -f /etc/xdg/autostart/nm-applet.desktop
    sudo sed -i "s/GNOME;\$/GNOME;Pantheon;/" /etc/xdg/autostart/indicator-application.desktop
    sudo systemctl restart accounts-daemon.service
}
APT_PACKAGES=(
    apt-transport-https
    autoconf
    automake
    bridge-utils
    build-essential
    curl
    dkms
    dmg2img
    dstat
    elementary-tweaks
    gfortran
    gimp
    git
    htop
    indicator-application
    kazam
    libblas-dev
    libbz2-dev
    libguestfs-tools
    libhdf5-100
    libhdf5-dev
    liblapack-dev
    libncurses5-dev
    libncursesw5-dev
    libreadline-dev
    libsqlite3-dev
    libssl-dev
    libtool
    libvirt-bin
    llvm
    nano
    ncdu
    pkg-config
    qemu
    qemu-kvm
    tmux
    tree
    uml-utilities
    virt-manager
    virt-top
    virtinst
    wget
    wingpanel-indicator-ayatana
    wireshark
    xclip
    xsltproc
    xz-utils
    zlib1g-dev
    zsh
)
