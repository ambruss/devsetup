#!/usr/bin/env bash

is_installed() {
    PY_VER=$(python_ver)
    PY_BIN=$(echo "python$PY_VER" | sed 's/\.[0-9]$//')
    cmd "$PY_BIN"
}

install() {
    PY_VER=$(python_ver)
    PY_URL=https://www.python.org/ftp/python/$PY_VER/Python-$PY_VER.tar.xz
    curl "$PY_URL" | tar xJ
    cdir "Python-$PY_VER"
    ./configure \
        --enable-optimizations \
        --enable-shared \
        --prefix=/usr/local \
        --with-ensurepip=install \
        LDFLAGS="-Wl,-rpath /usr/local/lib"
    make "-j$(nproc)"
    sudo make altinstall
    sudo rm -rf "../Python-$PY_VER"
}

python_ver() {
    latest https://www.python.org/downloads/ ">Python $VERSION_RE<"
}
