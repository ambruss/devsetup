is_installed() {
    getent passwd $(id -u) | grep -q zsh
}

install() {
    chsh -s $(env which zsh)
}
