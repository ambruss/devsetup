is_installed() {
    which dotenv-linter
}

install() {
    REPO=dotenv-linter/dotenv-linter
    VER=$(latest $REPO)
    URL=https://github.com/$REPO/releases/download/$VER/dotenv-linter-linux-x86_64.tar.gz
    curl $URL | tar xz
    mv dotenv-linter $BIN
}
