is_installed() {
    test -d $NODE
    # TODO check npm packages
}

install() {
    NODE_VER=$(latest https://nodejs.org/dist/latest/ "-($VERSION_RE)-")
    NODE_DIR=node-$NODE_VER-linux-x64
    NODE_URL=https://nodejs.org/dist/$NODE_VER/$NODE_DIR.tar.xz
    curl $NODE_URL | tar xJ
    rm -rf $NODE
    mv -f $NODE_DIR $NODE
    export NPM_CONFIG_PREFIX=$NODE
    for PACKAGE in ${NPM_PACKAGES[@]}; do
        npm install --global $PACKAGE
    done
}

NPM_PACKAGES=(
    tldr
)
