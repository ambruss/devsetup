#!/usr/bin/env bash
set -euo pipefail
test -z "${TRACE:-}" || set -x

VERSION_RE="v?[0-9]+(\.[0-9]+)+"
DIR=$(cd "$(dirname "$0")" && pwd)
mapfile -t MODULES < <(find "$DIR/modules" -type f -printf "%f\n" | sed 's|\.sh||' | sort)
INSTALL=()
DEPENDS=(
    "diff-so-fancy git-config"
    "kubectl minikube"
    "nodejs npm"
    "npm wps"
    "python venv"
    "venv gdcm"
)
INCLUDE=()
EXCLUDE=()
FORCE=false
NODEPS=false
DOTENV=
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
        --dotenv)       DOTENV=$2; shift;;
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
        install "$MOD"
    done

    if [ -n "$DOTENV" ]; then
        # shellcheck disable=SC2015
        info "Loading dotenv$($DRYRUN && echo ' (dry-run)' || true)"
        $DRYRUN || load_dotenv
    fi

    info "Devsetup complete"
}

help() {
cat <<EOF
Usage: $0 [OPTION...]

Automated development environment setup for Elementary OS.

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
      --dotenv FILE         Configure user-specific settings
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

load_dotenv() {  # load config from dotenv file
    if ! test -f "$DOTENV"; then
        info "$DOTENV not found - creating"
        sleep 2
        cp "$DIR/.env.sample" "$DOTENV"
        "${EDITOR:-nano}" "$DOTENV"
    fi

    info "Sourcing $DOTENV"
    # shellcheck disable=SC1090
    . "$DOTENV"

    if [ -n "${GIT_EMAIL:-}" ] && [ -n "${GIT_NAME:-}" ]; then
        info "Setting git email and username"
        git config --global user.email "$GIT_EMAIL"
        git config --global user.name "$GIT_NAME"
    fi
    if [ -n "${IPY_STARTUP:-}" ]; then
        info "Writing ipython startup script"
        IPY_FILE=~/.ipython/profile_default/startup/startup.py
        mkdir -p "$(dirname "$IPY_FILE")"
        echo "${IPY_STARTUP:1}" >"$IPY_FILE"
    fi
    if [ -n "${JIRA_CONFIG:-}" ]; then
        info "Writing JIRA CLI config"
        JIRA_FILE=~/.jira.d/config.yml
        mkdir -p "$(dirname "$JIRA_FILE")"
        echo "${JIRA_CONFIG:1}" >"$JIRA_FILE"
        chmod +x "$JIRA_FILE"
        info "Opening Chrome tab JIRA API-tokens"
        google-chrome https://id.atlassian.com/manage/api-tokens
    fi
    if [ -n "${SSH_KEY:-}" ] && [ -n "${SSH_PUB:-}" ]; then
        info "Setting up SSH keypair"
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        echo "${SSH_KEY:1}" >~/.ssh/id_rsa
        echo "$SSH_PUB" >~/.ssh/id_rsa.pub
        chmod 600 ~/.ssh/id_rsa
        eval "$(ssh-agent)"
        ssh-add ~/.ssh/id_rsa
    fi
    if [ -n "${SUBLIME_KEY:-}" ]; then
        info "Writing sublime license file"
        LICENSE_FILE=~/.config/sublime-text-3/Local/License.sublime_license
        mkdir -p "$(dirname "$LICENSE_FILE")"
        echo "${SUBLIME_KEY:1}" >"$LICENSE_FILE"
    fi
    if [ -n "${ZSH_PROFILE:-}" ]; then
        info "Writing zsh profile"
        ZSH_FILE=~/.oh-my-zsh/custom/custom.zsh
        mkdir -p "$(dirname "$ZSH_FILE")"
        echo "${ZSH_PROFILE:1}" >"$ZSH_FILE"
    fi
}

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
