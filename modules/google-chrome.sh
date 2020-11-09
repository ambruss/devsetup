#!/usr/bin/env bash

is_installed() {
    cmd google-chrome
}

install() {
    curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg --install google-chrome-stable_current_amd64.deb || sudo apt-get install -fqqy
    for EXTENSION in "${EXTENSIONS[@]}"; do
        google-chrome "$EXTENSION"
    done
}

EXTENSIONS=(
https://chrome.google.com/webstore/detail/adblock-plus-free-ad-bloc/cfhdojbkjhnklbpkdaibdccddilifddb
https://chrome.google.com/webstore/detail/i-dont-care-about-cookies/fihnjjcciajhdojfnbdddfaoknhalnja
https://chrome.google.com/webstore/detail/link-to-text-fragment/pbcodcjpfjdpcineamnnmbkkmkdpajjg
https://chrome.google.com/webstore/detail/markdown-here/elifhakcjgalahccnjkneoccemfahfoa
https://chrome.google.com/webstore/detail/markdown-to-jira/jjmmhbaklhogjgcccbmhfllhmfdamagg
https://chrome.google.com/webstore/detail/markdown-viewer/ckkdlimhmcjmikdlpkmbgfkaikojcbjk
https://chrome.google.com/webstore/detail/quick-jira/acdnmaeifljongleeegkkfnfcopblokj
https://chrome.google.com/webstore/detail/talend-api-tester-free-ed/aejoelaoggembcahagimdiliamlcdmfm
)
