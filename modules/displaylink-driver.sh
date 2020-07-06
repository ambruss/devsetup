#!/usr/bin/env bash

is_installed() {
    test -f "$CONF"
}

install() {
    SITE=https://www.displaylink.com
    FILE=$(curl $SITE/downloads/ubuntu | grep "/downloads/file\?id=\d+" | grep -o "\d+" | sort -V | tail -n1)
    URL="$SITE/downloads/file?id=$FILE"
    curl -o displaylink.zip -d"fileId=$FILE&accept_submit=Accept" "$URL"
    unzip displaylink.zip
    chmod +x ./displaylink-driver*.run
    # TODO make this non-interactive
    sudo ./displaylink-driver*.run
    echo "$CONFIG" | sudo tee "$CONF"
}

CONF=/usr/share/X11/xorg.conf.d/20-displaylink.conf
CONFIG="$(cat <<EOF
Section "Device"
  Identifier "DisplayLink"
  Driver "modesetting"
  Option "PageFlip" "false"
EndSection
EOF
)"
