#!/usr/bin/env bash

is_installed() {
    false
}

install() {
    remove_snapd
    remove_cloudinit
    patch_motd
    auto_login
}

remove_snap() {
    cmd snap || return
    info "Removing snapd"
    sudo snap remove --purge lxd
    sudo snap remove --purge core18
    sudo snap remove --purge snapd
    sudo apt-get purge -y snapd
}

remove_cloudinit() {
    cmd cloud-init || return
    info "Removing cloud-init"
    sudo apt-get purge -y cloud-init
}

patch_motd() {
    info "Patching motd"
    sudo chmod -x /etc/update-motd.d/10-help-text
    sudo chmod -x /etc/update-motd.d/50-motd-news
    sudo sed -i "s|if .*|if true; then|" /etc/update-motd.d/50-landscape-sysinfo
}

auto_login() {
    CONF=/etc/systemd/system/getty@tty1.service.d/override.conf
    test ! -f "$CONF" || return
    info "Enabling auto-login"
    sudo mkdir -p "$(dirname "$CONF")"
    cat >"$CONF" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin $USER %I $TERM
Type=idle
EOF
}
