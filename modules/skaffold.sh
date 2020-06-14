is_installed() {
    which skaffold
}

install() {
    SKAFFOLD_VER=$(latest GoogleContainerTools/skaffold)
    SKAFFOLD_URL=https://github.com/GoogleContainerTools/skaffold/releases/download/$SKAFFOLD_VER/skaffold-linux-amd64
    curl -o $BIN/skaffold $SKAFFOLD_URL
    chmod +x $BIN/skaffold
}
