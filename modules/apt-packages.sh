#!/usr/bin/env bash

is_installed() {
    OLD=$(apt list --installed 2>/dev/null | sed 's|([^/]+)/.*|\1|' | sort)
    NEW=$(comm -23 <(printf "%s\n" "${APT_PACKAGES[@]}" | sort) <(echo "$OLD"))
    test -z "$NEW" || return 1
}

install() {
    if ! cmd apt-add-repository; then
        sudo apt-get update -qq
        sudo apt-get install -qqy software-properties-common
    fi
    sudo apt-add-repository -nsy ppa:philip.scott/elementary-tweaks
    sudo apt-add-repository -nsy ppa:yunnxx/elementary
    sudo apt-get update -qq
    sudo apt-get install -qqy "${APT_PACKAGES[@]}"
    sudo sh -c "printf '[User]\nSystemAccount=true\n' > /var/lib/AccountsService/users/libvirt-qemu"
    sudo rm -f /etc/xdg/autostart/nm-applet.desktop
    sudo sed -i "s/GNOME;\$/GNOME;Pantheon;/" /etc/xdg/autostart/indicator-application.desktop
    sudo systemctl restart accounts-daemon.service
}

APT_PACKAGES=(
    apt-file
    apt-transport-https
    autoconf
    automake
    bridge-utils
    build-essential
    cmake
    curl
    dkms
    dmg2img
    docbook-xsl-ns
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
    librsvg2-bin
    libsqlite3-dev
    libssl-dev
    libtool
    libvirt-bin
    llvm
    meld
    nano
    ncdu
    octave
    pkg-config
    qemu
    qemu-kvm
    swig
    texlive-xetex
    tmux
    tree
    ttf-dejavu-extra
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
