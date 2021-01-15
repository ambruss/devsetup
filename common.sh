#!/usr/bin/env bash
set -aeuo pipefail
test -z "${TRACE:-}" || set -x

DIR=$(cd "$(dirname "$0")" && pwd)
DOTENV=false
DRYRUN=false
FORCE=false
SUDO=false
VERSION_RE="v?[0-9]+(\.[0-9]+)+"

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

# load config from dotenv file
load_dotenv() {(
    $DOTENV || test -f .env || return 0
    DOTENV="$DIR/.env"
    info "Loading $DOTENV"
    # shellcheck disable=SC2015
    $DRYRUN && return || true
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
        echo "$IPY_STARTUP" >"$IPY_FILE"
    fi
    if [ -n "${SSH_KEY:-}" ] && [ -n "${SSH_PUB:-}" ]; then
        info "Setting up SSH keypair"
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        echo "$SSH_KEY" >~/.ssh/id_rsa
        echo "$SSH_PUB" >~/.ssh/id_rsa.pub
        chmod 600 ~/.ssh/id_rsa
        eval "$(ssh-agent)"
        ssh-add ~/.ssh/id_rsa
    fi
    if [ -n "${SUBLIME_KEY:-}" ]; then
        info "Writing sublime license file"
        LICENSE_FILE=~/.config/sublime-text-3/Local/License.sublime_license
        mkdir -p "$(dirname "$LICENSE_FILE")"
        echo "$SUBLIME_KEY" >"$LICENSE_FILE"
    fi
    if [ -n "${ZSH_PROFILE:-}" ]; then
        info "Writing zsh profile"
        ZSH_FILE=~/.oh-my-zsh/custom/custom.zsh
        mkdir -p "$(dirname "$ZSH_FILE")"
        echo "$ZSH_PROFILE" >"$ZSH_FILE"
    fi
)}

install_module() {(  # install item from ./modules
    MOD=${1/=*/}
    VER=${1/$MOD/}
    # shellcheck disable=SC1090
    . "$DIR/modules/$MOD.sh"
    if $FORCE || ! is_installed; then
        info "Installing $MOD"
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

on_start() {  # create and use tempdir and register exit hook
    TMP=$(mktemp --directory --suffix .$$)
    cdir "$TMP"
    trap on_exit EXIT
}

on_exit() {  # clean up tempdir and log final status
    CODE=$?
    rm -rf "$TMP"
    kill 0
    test "$CODE" = 0 || fail "Command returned $CODE\nRun with TRACE=1 to debug"
    info "$0 finished without errors"
}
