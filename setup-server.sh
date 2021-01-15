#!/usr/bin/env bash
set -euo pipefail
test -z "${TRACE:-}" || set -x

# shellcheck disable=SC1090
. "$(dirname "$0")/common.sh"

SETUP=server
USAGE="Usage: $0 [OPTION...]

Automated home server setup on Ubuntu Server 20.04.

Options:
  -l, --list                List available modules
  -i, --include MOD[=VER]   Only install explicitly whitelisted modules
                            Optionally define module version to install
  -x, --exclude MOD         Skip installing explicitly blacklisted modules
  -f, --force               Force reinstalls even if module is already present
      --dry-run             Only print what would be installed
      --dotenv              Autocreate .env file for customizing user settings
"

MODULES=(
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
INSTALL=()
INCLUDE=()
EXCLUDE=()


main() {
    on_start

    while test $# -gt 0; do
    case $1 in
        -h|--help|help) echo "$USAGE" && exit;;
        -l|--list|list) list && exit;;
        -i|--include)   INCLUDE+=("$2"); shift;;
        -x|--exclude)   EXCLUDE+=("$2"); shift;;
        -f|--force)     FORCE=true;;
        --dry-run)      DRYRUN=true;;
        --dotenv)       DOTENV=true;;
        *)              fail "Invalid argument: $1 (run $0 help for usage)";;
    esac && shift
    done

    # validate modules
    for MOD in "${INCLUDE[@]}" "${EXCLUDE[@]}"; do
        NAME=${MOD/=*/}  # strip any version override
        echo " ${MODULES[*]} " | grep -q " $NAME " || fail "Invalid module $NAME"
    done

    # apply in/exclusions
    test -z "${INCLUDE[*]}" || MODULES=("${INCLUDE[@]}")
    test -z "${EXCLUDE[*]}" || for MOD in "${EXCLUDE[@]}"; do
        MODULES=("${MODULES[@]/$MOD}")
    done

    INSTALL=("${MODULES[@]}")
    info "Gathered install modules ${INSTALL[*]}"

    # define and create dirs
    CONFIG=$HOME/.config
    LOCAL=$HOME/local
    BIN=$LOCAL/bin
    SHARE=$LOCAL/share
    VENV=$LOCAL/venv
    mkdir -p "$BIN" "$CONFIG" "$SHARE"

    # pre-enable binaries by extending path
    export PATH=$BIN:$PATH

    # install server modules
    for MOD in "${INSTALL[@]}"; do
        install_module "$MOD"
    done

    load_dotenv
}

list() {
    echo "Available modules:"
    for MOD in "${MODULES[@]}"; do
        echo "  - $MOD"
    done
}


main "$@"
