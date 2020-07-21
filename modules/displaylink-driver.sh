#!/usr/bin/env bash

is_installed() {
    quiet modinfo evdi
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
}
