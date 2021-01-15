#!/usr/bin/env bash

is_installed() {
    false
}

install() {
    vbox_additions
    grub_config
    ufw_config
    sshd_config
    motd_config
    auto_login
}

vbox_additions() {
    sudo mkdir -p /media/cdrom
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
    sudo sed -i "s|#PasswordAuthentication yes|PasswordAuthentication no|" /etc/ssh/sshd_config
}

motd_config() {
    sudo chmod -x /etc/update-motd.d/10-help-text
    sudo chmod -x /etc/update-motd.d/50-motd-news
    sudo sed -i "s|if .*|if true; then|" /etc/update-motd.d/50-landscape-sysinfo
}

auto_login() {
    CONF=/etc/systemd/system/getty@tty1.service.d/override.conf
    sudo mkdir -p "$(dirname "$CONF")"
    sudo tee "$CONF" >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin $USER %I $TERM
Type=idle
EOF
}
