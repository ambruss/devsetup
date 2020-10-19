#!/usr/bin/env bash

is_installed() {
    cmd gdcmdump
}

install() {
    VER=$(latest malaterre/GDCM | sed 's/v//')
    URL="https://github.com/malaterre/GDCM/archive/v$VER.tar.gz"
    curl "$URL" | tar xz
    cdir build
    cmake \
        -DGDCM_BUILD_APPLICATIONS=1 \
        -DGDCM_BUILD_SHARED_LIBS=1 \
        -DGDCM_WRAP_PYTHON=1 \
        "../GDCM-$VER"
    make -j8
    sudo make install
    sudo ldconfig
    cp -r /usr/local/lib/*gdcm* "$VENV/lib/python*/site-packages"
}
