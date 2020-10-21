#!/usr/bin/env bash
test -n "${TRACE:-}" && set -o xtrace
set -o errexit
set -o nounset
set -o pipefail


main() {
    while test $# -gt 0; do
    case $1 in
        -h|--help|help) help && exit;;
        *) fail "Invalid argument: $1 (run $0 help for usage)";;
    esac && shift
    done

    if ! test -f .env; then
        log "Creating new .env for editing"
        sleep 2
        cp .env.example .env
        nano .env
    fi

    log "Sourcing .env"
    . .env

    if [ -n "${GIT_EMAIL:-}" -a -n "${GIT_NAME:-}" ]; then
        log "Setting git email and username"
        git config --global user.email "$GIT_EMAIL"
        git config --global user.name "$GIT_NAME"
    else
        log "GIT_EMAIL or GIT_NAME not set - skipping git config"
    fi

    if [ -n "${IPY_STARTUP:-}" ]; then
        log "Writing ipython startup script"
        IPY_FILE=~/.ipython/profile_default/startup/startup.py
        echo "$IPY_STARTUP" >"$IPY_FILE"
    else
        log "IPY_STARTUP not set - skipping startup script"
    fi

    if [ -n "${SSH_KEY:-}" -a -n "${SSH_PUB:-}" ]; then
        echo "$SSH_KEY" >~/.ssh/id_rsa
        echo "$SSH_PUB" >~/.ssh/id_rsa.pub
        chmod 600 ~/.ssh/id_rsa
        eval "$(ssh-agent)"
        ssh-add ~/.ssh/id_rsa
    else
        log "SSH_KEY or SSHA_PU not set - skipping ssh config"
    fi

    if [ -n "${SUBLIME_KEY:-}" ]; then
        log "Writing sublime license file"
        LICENSE_FILE=~/.config/sublime-text-3/Local/License.sublime_license
        echo "$SUBLIME_KEY" >"$LICENSE_FILE"
    else
        log "SUBLIME_KEY not set - skipping sublime registration"
    fi

    log "Configuration done"
}

help() {
cat <<EOF
Usage: $0

Automated configuration using the '.env' file.
Currently supports:
- Setting the global git email address and username
- Creating a custom ipython startup script
- Adding and configuring an existing SSH keypair
- Entering a Sublime Text license key
EOF
}

log() { printf "%s\n" "$*" >&2; }


main "$@"
