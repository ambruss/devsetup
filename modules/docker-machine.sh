is_installed() {
    which docker-machine
}

install() {
    DMACHINE_VER=$(latest docker/machine)
    DMACHINE_URL=https://github.com/docker/machine/releases/download/$DMACHINE_VER/docker-machine-Linux-x86_64
    curl -o $BIN/docker-machine $DMACHINE_URL
    chmod +x $BIN/docker-machine
}
