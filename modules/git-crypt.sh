is_installed() {
    which git-crypt
}

install() {
    test -d $SHARE/git-crypt || clone AGWA/git-crypt.git $SHARE/git-crypt
    cd $SHARE/git-crypt
    git pull
    make
    make install PREFIX=$LOCAL
}
