is_installed() {
    which miktexsetup
}

install() {
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    echo "deb http://miktex.org/download/ubuntu bionic universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get -qq update
    sudo apt-get -qq install -y miktex
    miktexsetup --user-link-target-directory="$BIN" finish
    initexmf --set-config-value "[MPM]AutoInstall=1"
}
