#!/usr/bin/env bash
set -euo pipefail
test -z "${TRACE:-}" || set -x

export DEBIAN_FRONTEND=noninteractive
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git" >&2
    sudo apt-get install -qqy git
fi
if ! test -d ~/workspace/bootstrap; then
    echo "Cloning ambruss/bootstrap" >&2
    mkdir -p ~/workspace
    git clone https://github.com/ambruss/bootstrap ~/workspace/bootstrap
fi

lsb_release -sd | grep -q elementary && SETUP=dev || SETUP=server
SCRIPT="setup-$SETUP.sh"
echo "Running $SCRIPT" >&2
~/workspace/bootstrap/"$SCRIPT" "$@"
