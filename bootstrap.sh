#!/usr/bin/env bash
test -n "${TRACE:-}" && set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

if ! command -v git >/dev/null 2>&1; then
    echo "Installing git" 1>&2
    sudo apt-get install -qqy git
fi
if ! test -d ~/workspace/devsetup; then
    echo "Cloning ambruss/devsetup" 1>&2
    mkdir -p ~/workspace
    git clone https://github.com/ambruss/devsetup.git ~/workspace/devsetup
fi

echo "Running devsetup.sh" 1>&2
~/workspace/devsetup/devsetup.sh
