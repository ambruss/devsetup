#!/usr/bin/env bash

is_installed() {
    OLD=$(apt list --installed 2>/dev/null | sed 's|([^/]+)/.*|\1|' | sort)
    NEW=$(comm -23 <(printf "%s\n" "${APT_PACKAGES[@]}" | sort) <(echo "$OLD"))
    test -z "$NEW" || return 1
}

install() { "install_$SETUP"; }

install_dev() {
    if ! cmd apt-add-repository; then
        sudo apt-get update -qq
        sudo apt-get install -qqy software-properties-common
    fi
    sudo apt-add-repository -nsy ppa:philip.scott/elementary-tweaks
    sudo apt-add-repository -nsy ppa:yunnxx/elementary
    install_server
    sudo sh -c "printf '[User]\nSystemAccount=true\n' >/var/lib/AccountsService/users/libvirt-qemu"
    sudo rm -f /etc/xdg/autostart/nm-applet.desktop
    sudo sed -i "s/GNOME;\$/GNOME;Pantheon;/" /etc/xdg/autostart/indicator-application.desktop
    sudo systemctl restart accounts-daemon.service
}

install_server() {
    sudo apt-get update -qq
    sudo apt-get upgrade -qqy
    sudo apt-get install -qqy "${APT_PACKAGES[@]}"
    sudo apt-get autoremove -qqy
}

# common apt packages for all setups
APT_PACKAGES=(
    apt-file
    apt-transport-https
    autoconf
    automake
    build-essential
    cifs-utils
    cmake
    curl
    dstat
    git
    htop
    libssl-dev
    nano
    ncdu
    pkg-config
    software-properties-common
    tmux
    tree
    wget
    zip
    zsh
)

# additional apt packages for the dev setup
APT_PACKAGES_DEV=(
    bridge-utils
    dkms
    dmg2img
    docbook-xsl-ns
    elementary-tweaks
    gfortran
    gimp
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
    libtool
    libvirt-bin
    llvm
    meld
    octave
    qemu
    qemu-kvm
    swig
    texlive-xetex
    ttf-dejavu-extra
    uml-utilities
    virt-manager
    virt-top
    virtinst
    wingpanel-indicator-ayatana
    wireshark
    xclip
    xsel
    xsltproc
    xz-utils
    zlib1g-dev
)

# additional apt packages for the server setup
APT_PACKAGES_SERVER=(
    openssh-server
    python3
    python3-venv
)

if [ "$SETUP" = dev ]; then
    APT_PACKAGES+=("${APT_PACKAGES_DEV[@]}")
else
    APT_PACKAGES+=("${APT_PACKAGES_SERVER[@]}")
fi
