#!/usr/bin/env bash
set -euo pipefail
test -z "${TRACE:-}" || set -x

# shellcheck disable=SC1090
. "$(dirname "$0")/common.sh"

SETUP=dev
USAGE="Usage: $0 [OPTION...]

Automated development environment setup on Elementary OS 5.1.

Examples:
  $0 --include python
  $0 --include jq=1.6 --force
  $0 --exclude sublime

Options:
  -l, --list                List available modules
  -i, --include MOD[=VER]   Only install explicitly whitelisted modules
                            Optionally define module version to install
  -x, --exclude MOD         Skip installing explicitly blacklisted modules
  -D, --no-deps             Skip installing module dependencies
  -f, --force               Force reinstalls even if module is already present
      --dry-run             Only print what would be installed
      --dotenv              Autocreate .env file for customizing user settings

"

mapfile -t MODULES < <(find "$DIR/modules" -type f -printf "%f\n" | sed 's|\.sh||' | sort)
INSTALL=()
DEPENDS=(
    "diff-so-fancy git-config"
    "kubectl minikube"
    "nodejs npm"
    "python venv"
    "venv gdcm"
)
INCLUDE=()
EXCLUDE=(server-config)
NODEPS=false


main() {
    while test $# -gt 0; do
    case $1 in
        -h|--help|help) echo "$USAGE" && exit;;
        -l|--list|list) list && exit;;
        -i|--include)   INCLUDE+=("$2"); shift;;
        -x|--exclude)   EXCLUDE+=("$2"); shift;;
        -D|--no-deps)   NODEPS=true;;
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

    # add module dependencies
    if $NODEPS; then
        INSTALL=("${MODULES[@]}")
    else
        add_deps
    fi
    info "Gathered install modules ${INSTALL[*]}"

    # define and create dirs
    CONFIG=$HOME/.config
    LOCAL=$HOME/local
    BIN=$LOCAL/bin
    SHARE=$LOCAL/share
    VENV=$LOCAL/venv
    NODE=$LOCAL/node
    GO=$LOCAL/go
    mkdir -p "$BIN" "$CONFIG" "$SHARE"

    # create and use tempdir (and clean up on exit)
    TMP=$(mktemp --directory --suffix .$$)
    cdir "$TMP"
    trap 'info "Cleaning tempdir"; rm -rf $TMP; kill 0' EXIT

    # pre-enable binaries by extending path and setting node vars
    export PATH=$BIN:$VENV/bin:$NODE/bin:$GO/bin:$PATH
    export NODE_PATH="$NODE/lib/node_modules"
    export NPM_CONFIG_PREFIX=$NODE

    # install selected modules
    for MOD in "${INSTALL[@]}"; do
        install_module "$MOD"
    done

    load_dotenv

    info "$0 finished"
}

list() {
    echo "Available modules:"
    for MOD in "${MODULES[@]}"; do
        echo "  - $MOD"
    done
}

add_deps() {  # resolve and add dependency modules
    info "Resolving dependencies"
    for MOD in "${MODULES[@]}"; do
        # add apt packages as a dependency for every module
        test -z "$MOD" || INSTALL+=("apt-packages $MOD")
    done
    for DEP in "${DEPENDS[@]}"; do
        # add dependencies (MOD1) defined in DEPENDS if MOD2 is to be installed
        MOD1=${DEP/ */}
        MOD2=${DEP/* /}
        MOD1_=$(printf "%s\n" "${MODULES[@]}" | grep "$MOD1" || echo "$MOD1")
        MOD2_=$(printf "%s\n" "${MODULES[@]}" | grep "$MOD2" || true)
        test -z "$MOD2_" || INSTALL+=("$MOD1_ $MOD2_")
    done
    # run a topological sort on the 2-tuples to get a flat list
    mapfile -t INSTALL < <(printf "%s\n" "${INSTALL[@]}" | tsort)
}


main "$@"
