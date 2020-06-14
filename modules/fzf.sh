is_installed() {
    test -d $SHARE/fzf
}

install() {
    rm -rf $SHARE/fzf
    git clone --depth 1 https://github.com/junegunn/fzf.git $SHARE/fzf
    sudo $SHARE/fzf/install --all
}
