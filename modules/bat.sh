is_installed() {
    which bat
}

install() {
    BAT_VER=$(latest sharkdp/bat)
    BAT_DIR=bat-$BAT_VER-x86_64-unknown-linux-gnu
    BAT_URL=https://github.com/sharkdp/bat/releases/download/$BAT_VER/$BAT_DIR.tar.gz
    curl $BAT_URL | tar xz
    mv -f $BAT_DIR/bat $BIN
}
