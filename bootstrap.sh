#!/usr/bin/env bash
test -n "${TRACE:-}" && set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

command -v git >/dev/null 2>&1 || sudo apt-get install -qqy git
mkdir -p ~/workspace
test -d devsetup || git clone git@github.com:ambruss/devsetup.git ~/workspace
~/workspace/devsetup/devsetup.sh
