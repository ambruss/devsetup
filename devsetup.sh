#!/usr/bin/env bash
test -n "${TRACE:-}" && set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

VERSION_RE="v?[0-9]+(\.[0-9]+)+"
DIR=$(cd "$(dirname "$0")" && pwd)
mapfile -t MODULES < <(find "$DIR/modules" -type f -printf "%f\n" | sed 's|\.sh||' | sort)
DEPENDS=(
    "diff-so-fancy git-config"
    "kubectl minikube"
    "python venv"
)
INCLUDE=()
EXCLUDE=()
FORCE=false
NODEPS=false
DRYRUN=false
SUDO=false


main() {
    while test $# -gt 0; do
    case $1 in
        -h|--help|help) help && exit;;
        -l|--list|list) list && exit;;
        -i|--include)   INCLUDE+=("$2"); shift;;
        -x|--exclude)   EXCLUDE+=("$2"); shift;;
        -f|--force)     FORCE=true;;
        -D|--no-deps)   NODEPS=true;;
        --dry-run)      DRYRUN=true;;
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

    if $NODEPS; then
        INSTALL=("${MODULES[@]}")
    else
        info "Resolving dependencies"
        INSTALL=()
        for MOD in "${MODULES[@]}"; do
            test -z "$MOD" || INSTALL+=("apt-packages $MOD")
        done
        for DEP in "${DEPENDS[@]}"; do
            MOD1=${DEP/ */}
            MOD2=${DEP/* /}
            MOD1_=$(printf "%s\n" "${MODULES[@]}" | grep "$MOD1" || echo "$MOD1")
            MOD2_=$(printf "%s\n" "${MODULES[@]}" | grep "$MOD2" || true)
            test -z "$MOD2_" || INSTALL+=("$MOD1_ $MOD2_")
        done
        mapfile -t INSTALL < <(printf "%s\n" "${INSTALL[@]}" | tsort)
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
    cd "$TMP"
    trap 'rm -rf $TMP; kill 0' EXIT
    # immediately enable running installed modules
    export PATH=$VENV/bin:$NODE/bin:$GO/bin:$BIN:$PATH
    # install each module
    for MOD in "${INSTALL[@]}"; do
        install "$MOD"
    done

    info "Devsetup complete"
}

help() {
cat <<EOF
Usage: $0 [OPTION...]

Automated development environment setup on Elementary OS.

Examples:
  $0 --include python
  $0 --include jq=1.6 --force
  $0 --exclude sublime

Options:
  -l, --list                List available modules
  -i, --include MOD[=VER]   Only install explicitly whitelisted modules
                            Optionally define module version to install
  -x, --exclude MOD         Skip installing explicitly blacklisted modules
  -f, --force               Force reinstalls even if already present
  -D, --no-deps             Skip installing dependencies
      --dry-run             Only print what would be installed

EOF
}

list() {
    echo "Available modules:"
    for MOD in "${MODULES[@]}"; do
        echo "  - $MOD"
    done
}

# basic tool aliases
curl() { env curl -fLSs --retry 2 --connect-timeout 5 "$@"; }
grep() { env grep -P "$@"; }
sed() { env sed -E "$@"; }
cmd() { quiet command -v "$1"; }
cdir() { test -d "$1" || mkdir -p "$1"; cd "$1" || fail "Couldn't cd into $1"; }
clone() { git clone --depth 1 "https://github.com/$1.git" "${@:2}"; }

# logging helpers
log() { printf "%s${EOL:-\n}" "$*" >&2; }
C_INFO=$(tput setaf 2)
C_WARN=$(tput setaf 3)
C_ERROR=$(tput setaf 1)
C_NULL=$(tput sgr0)
info() { log "[${C_INFO}INFO${C_NULL}]" "$@"; }
warn() { log "[${C_WARN}WARNING${C_NULL}]" "$@"; }
error() { log "[${C_ERROR}ERROR${C_NULL}]" "$@"; }
fail() { error "$@"; exit "${EXIT_CODE:-1}"; }
quiet() { "$@" >/dev/null 2>&1; }

install() {(  # install item from ./modules
    MOD=${1/=*/}
    VER=${1/$MOD/}
    # shellcheck disable=SC1090
    . "$DIR/modules/$MOD.sh"
    if $FORCE || ! is_installed; then
        # shellcheck disable=SC2015
        info "Installing $MOD$($DRYRUN && echo ' (dry-run)' || true)"
        test -z "$VER" || info "Using version override $VER"
        $DRYRUN || install
    else
        info "Skipping $MOD (already installed)"
    fi
)}

latest() {  # get latest version string from a release page
    test -z "${VERSION:-}" || { echo "$VERSION" && return; }
    URL=$1
    REGEX="${2:-tag/$VERSION_RE}"
    echo "$1" | grep -q "^http" || URL=https://github.com/$1/releases
    VER=$(curl "$URL" \
        | grep -o "[^0-9.]*${VERSION_RE}[^0-9.]*" \
        | grep -v "$VERSION_RE-(alpha|beta|dev|rc)" \
        | grep -o -- "$REGEX" \
        | grep -o "$VERSION_RE" \
        | sort -rV \
        | head -n1)
    # shellcheck disable=SC2015
    test -n "$VER" && echo "$VER" || fail "Could not retrieve version from $URL"
}

sudo() {  # maintain sudo after 1st prompt
    if ! $SUDO; then
        command sudo true
        while true; do
            sleep 60 && command sudo -n true
        done &
        SUDO=true
    fi
    command sudo "$@"
}


main "$@"
