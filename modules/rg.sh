is_installed() {
    which rg
}

install() {
    RG_VER=$(latest BurntSushi/ripgrep)
    RG_DIR=ripgrep-$RG_VER-x86_64-unknown-linux-musl
    RG_URL=https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/$RG_DIR.tar.gz
    curl $RG_URL | tar xz
    mv -f $RG_DIR/rg $BIN
}
