#!/usr/bin/env bash
set -euo pipefail
test -z "${TRACE:-}" || set -x

if ! command -v git >/dev/null 2>&1; then
    echo "Installing git" >&2
    sudo apt-get install -qqy git
fi
if ! test -d ~/workspace/devsetup; then
    echo "Cloning ambruss/devsetup" >&2
    mkdir -p ~/workspace
    git clone https://github.com/ambruss/devsetup ~/workspace/devsetup
fi

echo "Running devsetup.sh" >&2
~/workspace/devsetup/devsetup.sh "$@"
