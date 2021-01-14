#!/usr/bin/env bash

is_installed() {
    false
}

install() {
    remove_snapd
    remove_cloudinit
    install_vbox_additions
    grub_config
    ufw_config
    sshd_config
    patch_motd
    auto_login
}

remove_snapd() {
    cmd snap || return 0
    info "Removing snapd"
    sudo snap remove --purge lxd
    sudo snap remove --purge core18
    sudo snap remove --purge snapd
    sudo apt-get purge -y snapd
}

remove_cloudinit() {
    cmd cloud-init || return 0
    info "Removing cloud-init"
    sudo apt-get purge -y cloud-init
}

install_vbox_additions() {
    sudo mkdir /media/cdrom
    sudo mount /dev/cdrom /media/cdrom || {
        info "Skipping vbox additions - cannot mount /dev/cdrom to /media/cdrom"
        return 0
    }
    test -x /media/cdrom/VBoxLinuxAdditions.run || {
        info "Skipping vbox additions - /media/cdrom/VBoxLinuxAdditions.run not found"
        return 0
    }
    sudo /media/cdrom/VBoxLinuxAdditions.run
    sudo umount /media/cdrom
    sudo rm -rf /media/cdrom
}

grub_config() {
    grep -q "#GRUB_GFXMODE" /etc/default/grub || $FORCE || return 0
    info "Setting grub resolution"
    sudo sed -i 's|#GRUB_GFXMODE=.*|GRUB_GFXMODE=1024x768x32\nGRUB_GFXPAYLOAD_LINUX="keep"|' /etc/default/grub
    sudo update-grub
}

ufw_config() {
    sudo ufw enable
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
}

sshd_config() {
    grep -q "#PasswordAuthentication yes" /etc/ssh/sshd_config || $FORCE || return 0
    info "Disabling SSH password auth"
    sudo sed -i "s|#PasswordAuthentication yes|PasswordAuthentication no|" /etc/ssh/sshd_config
}

patch_motd() {
    info "Patching motd"
    sudo chmod -x /etc/update-motd.d/10-help-text
    sudo chmod -x /etc/update-motd.d/50-motd-news
    sudo sed -i "s|if .*|if true; then|" /etc/update-motd.d/50-landscape-sysinfo
}

auto_login() {
    CONF=/etc/systemd/system/getty@tty1.service.d/override.conf
    test ! -f "$CONF" || $FORCE || return 0
    info "Enabling auto-login"
    sudo mkdir -p "$(dirname "$CONF")"
    sudo tee "$CONF" >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin $USER %I $TERM
Type=idle
EOF
}
