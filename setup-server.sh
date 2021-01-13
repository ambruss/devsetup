#!/usr/bin/env bash
set -euo pipefail
test -z "${TRACE:-}" || set -x

# shellcheck disable=SC1090
. "$(dirname "$0")/common.sh"

SETUP=server
USAGE="
Usage: $0 [OPTION...]

Automated home server setup on Ubuntu Server 20.04.

Options:
  -f, --force               Force reinstalls even if module is already present
      --dry-run             Only print what would be installed
      --dotenv              Autocreate .env file for customizing user settings
"

INSTALL=(
    apt-packages
    bat
    diff-so-fancy
    docker
    exa
    fd
    git-config
    git-crypt
    jq
    micro
    nanorc
    oh-my-zsh
    rg
    server-config
    venv
)


main() {
    while test $# -gt 0; do
    case $1 in
        -h|--help|help) echo "$USAGE" && exit;;
        -f|--force)     FORCE=true;;
        --dry-run)      DRYRUN=true;;
        --dotenv)       DOTENV=true;;
        *)              fail "Invalid argument: $1 (run $0 help for usage)";;
    esac && shift
    done

    # define and create dirs
    CONFIG=$HOME/.config
    LOCAL=$HOME/local
    BIN=$LOCAL/bin
    SHARE=$LOCAL/share
    mkdir -p "$BIN" "$CONFIG" "$SHARE"

    # create and use tempdir (and clean up on exit)
    TMP=$(mktemp --directory --suffix .$$)
    cdir "$TMP"
    trap 'info "Cleaning tempdir"; rm -rf $TMP; kill 0' EXIT

    # pre-enable binaries by extending path
    export PATH=$BIN:$PATH

    # install server modules
    for MOD in "${INSTALL[@]}"; do
        install_module "$MOD"
    done

    load_dotenv

    info "$0 finished"
}


main "$@"
