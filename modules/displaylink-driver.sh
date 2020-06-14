is_installed() {
    test -f $DISPLAYLINK_CONF
}

install() {
    DISPLAYLINK_SITE=https://www.displaylink.com
    DISPLAYLINK_FILE=$(curl $DISPLAYLINK_SITE/downloads/ubuntu | grep "/downloads/file\?id=\d+" | grep -o "\d+" | sort -V | tail -n1)
    DISPLAYLINK_URL="$DISPLAYLINK_SITE/downloads/file?id=$DISPLAYLINK_FILE"
    curl -o displaylink.zip -d"fileId=$DISPLAYLINK_FILE&accept_submit=Accept" $DISPLAYLINK_URL
    unzip displaylink.zip
    chmod +x ./displaylink-driver*.run
    # TODO make this non-interactive
    sudo ./displaylink-driver*.run
    echo "$CONFIG" | sudo tee $DISPLAYLINK_CONF
}

DISPLAYLINK_CONF=/usr/share/X11/xorg.conf.d/20-displaylink.conf
CONFIG="
Section "Device"
  Identifier "DisplayLink"
  Driver "modesetting"
  Option "PageFlip" "false"
EndSection
"
