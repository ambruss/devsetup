is_installed() {
    which diff-so-fancy
}

install() {
    DIFF_URL=https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
    curl -o $BIN/diff-so-fancy $DIFF_URL
    chmod +x $BIN/diff-so-fancy
}
