is_installed() {
    which google-chrome
}

install() {
    curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg --install google-chrome-stable_current_amd64.deb || sudo apt-get install -yf
}
