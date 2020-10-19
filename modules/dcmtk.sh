#!/usr/bin/env bash

is_installed() {
    cmd dcmdump
}

install() {
    VER=$(latest DCMTK/dcmtk "DCMTK-$VERSION_RE")
    URL="https://github.com/DCMTK/dcmtk/archive/DCMTK-$VER.tar.gz"
    curl "$URL" | tar xz
    cdir build
    cmake \
        -DDCMTK_ENABLE_BUILTIN_DICTIONARY=1 \
        -DDCMTK_ENABLE_CXX11=1 \
        -DBUILD_SHARED_LIBS=1 \
        "../dcmtk-DCMTK-$VER"
    make -j8
    sudo make install
    sudo ldconfig
}
