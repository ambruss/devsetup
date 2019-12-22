#/usr/bin/env sh
export USAGE="
Automated development environment and toolset setup on Elementary OS.

Usage:
  $0 [OPTION...]

Options:
  -i, --include APP         Only install explicitly whitelisted tools
  -x, --exclude APP         Skip installing explicitly blacklisted tools
  -v, --version APP=VER     Install tool version VER instead of latest
  -f, --force               Force tool re-installs even if already present

Tools supported via --include/--exclude:
  - apt-packages (dstat git htop jq nano ncdu tmux tree zsh [+libs])
  - oh-my-zsh (zsh++)
  - nanorc (nano++)
  - elementary-tweaks (win-style)
  - google-chrome
  - subl (sublime editor)
  - nvim (neovim - vim++)
  - bat (cat++)
  - exa (ls++)
  - rg (ripgrep - grep++)
  - fd (find++)
  - fzf (fuzzy find - complements [oh-my-]zsh)
  - diff-so-fancy (git diff++)
  - python (supports version override N.N.N)
  - venv (compose httpie ipython)
  - node
  - docker
  - kubectl (supports version override vN.N.N)
  - helm (supports version override vN.N.N)
  - skaffold
  - minikube
"

# common version regex
export VERSION_RE="v?[0-9]+(\.[0-9]+)+"

# tools marked as included
export INCLUDE=
# tools marked as excluded
export EXCLUDE=
# version overrides
export VERSION=
# toggle forcing reinstalls
export FORCE=false


# MAIN BEGIN
main() {

test "$DEBUG" && set -o xtrace
set -o errexit
set -o nounset

local BIN=/usr/local/bin
local SHARE=/usr/share
local VENV=$HOME/.venv
local NODE=$HOME/.node
while [ $# -gt 0 ]; do
    case $1 in
        -i|--include) INCLUDE="$INCLUDE $2"; shift;;
        -x|--exclude) EXCLUDE="$EXCLUDE $2"; shift;;
        -v|--version) VERSION="$VERSION $2"; shift;;
        -f|--force) FORCE=true;;
        -h|--help) echo "$USAGE"; exit 0;;
        *) echo -e "Unkown arg $1\n$USAGE" >&2; exit 1;;
    esac
    shift
done

cd /tmp

should_install apt-packages is_installed_apt && (
log "Installing apt-packages"
sudo apt-get -qq update
sudo apt-get -qq install -y $APT_PACKAGES
)

which zsh >/dev/null && getent passwd $(id -u) | grep -vq zsh && (
log "Setting user shell to zsh"
chsh -s $(which zsh)
)

should_install oh-my-zsh "test -d ~/.oh-my-zsh" && (
log "Installing oh-my-zsh"
rm -rf ~/.oh-my-zsh
OHMYZSH_DIR=~/.oh-my-zsh/custom
OHMYZSH_URL=https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
curl -LSs $OHMYZSH_URL | sh
(
    cd $OHMYZSH_DIR/plugins
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git
)
sed_zshrc() { sed -i "s|$1|$2|" ~/.zshrc; }
sed_zshrc 'ZSH_THEME="robbyrussell"'       'ZSH_THEME="devsetup"'
sed_zshrc '# DISABLE_UPDATE_PROMPT="true"' 'DISABLE_UPDATE_PROMPT="true"'
sed_zshrc '# HIST_STAMPS="mm/dd/yyyy"'     'HIST_STAMPS="yyyy-mm-dd"'
sed_zshrc '^plugins=.*' 'plugins=(extract git httpie z zsh-autosuggestions zsh-syntax-highlighting)'
echo "$ZSH_PROFILE" | sed "s|\$VENV|$VENV|;s|\$NODE|$NODE|" >$OHMYZSH_DIR/devsetup.zsh
echo "$ZSH_THEME" >$OHMYZSH_DIR/themes/devsetup.zsh-theme
)

test -z "$(git config --global --get user.name)" && (
log "Configuring git"
git config --global user.name $(id -un)
git config --global user.email $(id -un)@$(hostname)
git config --global alias.patch "!git --no-pager diff --no-color"
git config --global alias.lg "log --abbrev-commit --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
)

should_install nanorc "test -f ~/.nanorc" && (
log "Installing nanorc"
NANORC_URL=https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh
curl -LSs $NANORC_URL | sh
find ~/.nano -type f | xargs sed -i "s/normal/white/g"
echo "$NANORC" >>~/.nanorc
)

should_install elementary-tweaks "apt show elementary-tweaks" && (
log "Installing elementary-tweaks"
sudo add-apt-repository -y ppa:philip.scott/elementary-tweaks
sudo apt-get -qq install -y elementary-tweaks
)

should_install google-chrome && (
log "Installing chrome (google-chrome)"
curl -LSsO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg --install google-chrome-stable_current_amd64.deb || sudo apt-get install -yf
)

should_install subl && (
log "Installing sublime (subl)"
curl -LSs https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/dev/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get -qq update
sudo apt-get -qq install -y sublime-text
)

should_install nvim && (
log "Installing neovim (nvim)"
NVIM_VER=$(latest neovim/neovim)
NVIM_URL=https://github.com/neovim/neovim/releases/download/$NVIM_VER/nvim.appimage
curl -LSso nvim $NVIM_URL
chmod +x nvim
sudo mv -f nvim $BIN
)

should_install bat && (
log "Installing bat (cat)"
BAT_VER=$(latest sharkdp/bat)
BAT_DIR=bat-$BAT_VER-x86_64-unknown-linux-gnu
BAT_URL=https://github.com/sharkdp/bat/releases/download/$BAT_VER/$BAT_DIR.tar.gz
curl -LSs $BAT_URL | tar xz
sudo mv -f $BAT_DIR/bat $BIN
)

should_install exa && (
log "Installing exa (ls)"
EXA_VER=$(latest ogham/exa)
EXA_BIN=exa-linux-x86_64
EXA_ZIP=$EXA_BIN-$(echo $EXA_VER | sed 's|v||').zip
EXA_URL=https://github.com/ogham/exa/releases/download/$EXA_VER/$EXA_ZIP
curl -LSsO $EXA_URL
unzip $EXA_ZIP
sudo mv -f $EXA_BIN $BIN/exa
)

should_install rg && (
log "Installing ripgrep (rg)"
RG_VER=$(latest BurntSushi/ripgrep)
RG_DIR=ripgrep-$RG_VER-x86_64-unknown-linux-musl
RG_URL=https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/$RG_DIR.tar.gz
curl -LSs $RG_URL | tar xz
sudo mv -f $RG_DIR/rg $BIN
)

should_install fd && (
log "Installing advanced find (fd)"
FD_VER=$(latest sharkdp/fd)
FD_DIR=fd-$FD_VER-x86_64-unknown-linux-gnu
FD_URL=https://github.com/sharkdp/fd/releases/download/$FD_VER/$FD_DIR.tar.gz
curl -LSs $FD_URL | tar xz
sudo mv -f $FD_DIR/fd $BIN
)

should_install fzf && (
log "Installing fuzzy find (fzf)"
sudo rm -rf $SHARE/fzf
sudo git clone --depth 1 https://github.com/junegunn/fzf.git $SHARE/fzf
sudo $SHARE/fzf/install --all --no-bash
)

should_install diff-so-fancy && (
log "Installing diff-so-fancy (git diff)"
DIFF_URL=https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
curl -LSso diff-so-fancy $DIFF_URL
chmod +x diff-so-fancy
sudo mv -f diff-so-fancy $BIN
eval $(diff-so-fancy --colors)
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
git config --global --bool diff-so-fancy.markEmptyLines false
git config --global --bool diff-so-fancy.changeHunkIndicators false
git config --global --bool diff-so-fancy.stripLeadingSymbols false
git config --global diff-so-fancy.rulerWidth 47
)

PY_VER_ARG=$(echo $VERSION | grep python= | sed -E "s|.*python=($VERSION_RE).*|\1|")
PY_VER=${PY_VER_ARG:-$(latest https://www.python.org/downloads/ "Python ($VERSION_RE)")}
PY_URL=https://www.python.org/ftp/python/$PY_VER/Python-$PY_VER.tar.xz
PY_BIN=$(echo python$PY_VER | sed 's/\.[0-9]$//')
should_install python "which $PY_BIN" && (
log "Installing python"
curl -LSs $PY_URL | tar xJ
(
    cd Python-$PY_VER
    ./configure \
        --prefix=/usr/local \
        --enable-optimizations \
        --enable-shared \
        --with-ensurepip=install \
        LDFLAGS="-Wl,-rpath /usr/local/lib"
    make -j8
    sudo make altinstall
    sudo $PY_BIN -m pip install virtualenv
)
)

should_install venv "test -d $VENV" && (
log "Installing python venv"
rm -rf $VENV
virtualenv -p $PY_BIN $VENV
$VENV/bin/pip install $PIP_PACKAGES
PYPPETEER_CHROMIUM_REVISION=$(curl -LSs https://storage.googleapis.com/chromium-browser-snapshots/Linux_x64/LAST_CHANGE) \
$VENV/bin/pyppeteer-install
$VENV/bin/ipython profile create
sed_ipy() { sed -i "s|^#$1.*|$1 = $2|" ~/.ipython/profile_default/ipython_config.py; }
sed_ipy c.InteractiveShellApp.extensions "['autoreload']"
sed_ipy c.InteractiveShellApp.exec_lines "['%autoreload 2']"
sed_ipy c.TerminalIPythonApp.display_banner False
sed_ipy c.TerminalInteractiveShell.confirm_exit False
sed_ipy c.TerminalInteractiveShell.editor "'nano'"
sed_ipy c.TerminalInteractiveShell.term_title_format "'ipy {cwd}'"
sed_ipy c.Completer.greedy True
)

should_install node && (
log "Installing nodejs"
NODE_VER=$(latest https://nodejs.org/dist/latest/ "-($VERSION_RE)-")
NODE_DIR=node-$NODE_VER-linux-x64
NODE_URL=https://nodejs.org/dist/latest/$NODE_DIR.tar.xz
curl -LSs $NODE_URL | tar xJ
rm -rf $NODE
sudo mv -f $NODE_DIR $NODE
PATH="$NODE/bin:$PATH" NPM_CONFIG_PREFIX=$NODE npm install --global tldr
)

should_install docker && (
log "Installing docker"
curl -LSs https://get.docker.com | sh
sudo usermod -aG docker $(id -un)
)

should_install kubectl && (
log "Installing kubectl"
KUBE_VER_ARG=$(echo $VERSION | grep kubectl= | sed -E "s|.*kubectl=($VERSION_RE).*|\1|")
KUBE_VER=${KUBE_VER_ARG:-$(curl -LSs https://storage.googleapis.com/kubernetes-release/release/stable.txt)}
KUBE_URL=https://storage.googleapis.com/kubernetes-release/release/$KUBE_VER/bin/linux/amd64/kubectl
curl -LSso kubectl $KUBE_URL
chmod +x kubectl
sudo mv -f kubectl $BIN
)

should_install helm && (
log "Installing helm"
HELM_VER_ARG=$(echo $VERSION | grep helm= | sed -E "s|.*helm=($VERSION_RE).*|\1|")
HELM_VER=${HELM_VER_ARG:-$(latest helm/helm "-($VERSION_RE)-")}
HELM_URL=https://get.helm.sh/helm-$HELM_VER-linux-amd64.tar.gz
curl -LSs $HELM_URL | tar xz
sudo mv -f linux-amd64/helm $BIN
)

should_install skaffold && (
log "Installing skaffold"
SKAFFOLD_VER=latest
SKAFFOLD_URL=https://storage.googleapis.com/skaffold/releases/$SKAFFOLD_VER/skaffold-linux-amd64
curl -LSso skaffold $SKAFFOLD_URL
chmod +x skaffold
sudo mv -f skaffold $BIN
)

should_install minikube && (
log "Installing minikube"
MINIKUBE_VER=latest
MINIKUBE_URL=https://storage.googleapis.com/minikube/releases/$MINIKUBE_VER/minikube-linux-amd64
curl -LSso minikube $MINIKUBE_URL
chmod +x minikube
sudo mv -f minikube $BIN
minikube config set cpus 1
minikube config set disk-size 8192
minikube config set memory 4096
minikube config set vm-driver none
minikube config set WantNoneDriverWarning false
minikube config set WantUpdateNotification false
KUBE_VER=$(kubectl version 2>/dev/null | grep -Eo $VERSION_RE | head -1)
test -n "$KUBE_VER" && minikube config set kubernetes-version $KUBE_VER
)

log "Devsetup complete"
return 0

# MAIN END
}


log() {
    printf "\033[1;32m[INFO]\033[0m %s\n" "$*"
}


# get and maintain sudo
export SUDO_ENABLED=false
sudo() {
    if ! $SUDO_ENABLED; then
        /usr/bin/sudo true
        keep_sudo() {(
            set +x
            sleep 60
            /usr/bin/sudo -n true
            kill -0 "$$" 2>/dev/null || exit
        )}
        while true; do
            keep_sudo
        done &
        SUDO_ENABLED=true
    fi
    /usr/bin/sudo "$@"
}


# get latest version from a release page
latest() {
    local REPO="$1"
    local RE="${2:-/($VERSION_RE)/}"
    echo $REPO | grep -Eq "^http" || REPO=https://github.com/$REPO/releases
    curl -LSs $REPO | grep -Eo "href.*$RE" | sed -E "s|.*$RE.*|\1|" | head -n1
}


# return 0 if a tool should be installed
should_install() {
    local TOOL="$1"
    local IS_INSTALLED="${2:-which $TOOL}"
    if [ "$INCLUDE" ]; then
        echo $INCLUDE | grep -q $TOOL || return 1
    elif [ "$EXCLUDE" ]; then
        echo $EXCLUDE | grep -q $TOOL && return 1
    fi
    $FORCE && return 0
    eval "$IS_INSTALLED" >/dev/null 2>&1 && return 1
    return 0
}


# return 0 if all packages in APT_PACKAGES are installed
is_installed_apt() {
    apt list --installed 2>/dev/null | sed -E 's|([^/]+)/.*|\1|' >apt.list
    for PACKAGE in $APT_PACKAGES; do
        grep -Eq "^$PACKAGE\$" apt.list || return 1
    done
    return 0
}


APT_PACKAGES=$(cat <<EOF
apt-transport-https
build-essential
curl
dstat
git
htop
jq
libbz2-dev
libncurses5-dev
libncursesw5-dev
libreadline-dev
libsqlite3-dev
libssl-dev
llvm
nano
ncdu
software-properties-common
tmux
tree
tk-dev
xz-utils
zlib1g-dev
zsh
EOF
)


PIP_PACKAGES=$(cat <<EOF
apscheduler
arrow
black
bokeh
bs4
delorean
docker-compose
fastapi
httpie
invoke
ipython
keras
matplotlib
numpy
pandas
pendulum
pillow
pip-compile-multi
pipenv
poetry
psutil
pyqt5
pytest
pytest-bandit
pytest-cov
pytest-flake8
pytest-mock
pytest-mypy
pytest-pylint
python-dateutil
pytz
pyyaml
requests
requests-html
scikit-learn
scipy
scrapy
sqlalchemy
typer[all]
yapf
yappi
EOF
)


NANORC=$(cat <<EOF
set autoindent
set morespace
set multibuffer
set nohelp
set nonewlines
set constantshow
set linenumbers
set positionlog
set smarthome
set smooth
set softwrap
set suspend
set regexp
set tabsize 4
set tabstospaces
bind ^H help all
bind ^Q exit all
bind ^O insert main
bind ^S savefile main
bind ^W writeout main
bind ^F whereis all
bind ^G findnext all
bind ^D findprevious all
bind ^R replace main
bind ^J gotoline main
bind ^B mark main
bind ^C copytext main
bind ^X cut main
bind ^V uncut main
bind ^Space complete main
bind ^I indent main
bind ^U unindent main
bind ^K comment main
bind ^Z undo main
bind ^Y redo main
bind ^N nextword main
bind ^P prevword main
bind M-N nextbuf main
bind M-P prevbuf main
bind M-Z suspend main
EOF
)


ZSH_PROFILE=$(cat <<'EOF'
setopt autocd autopushd pushdignoredups

export _Z_CMD=j
export CHANGE_MINIKUBE_NONE_USER=true
export DOCKER_BUILDKIT=1
export EDITOR=nano
export MINIKUBE_IN_STYLE=false
export NPM_CONFIG_PREFIX=$NODE
export PAGER="less -RF"
export PATH=$VENV/bin:$NODE/bin:$PATH
export REPORTMEMORY=10240
export REPORTTIME=5
export TIMEFMT="$TIMEFMT mem %M"

alias cat="bat"
alias d="dirs -v | head -5"
alias help="tldr -t base16"
alias ls="exa -ahl --git --group-directories-first --time-style=long-iso"
alias top="htop"
alias tree="tree --dirsfirst --sort=version"
alias zshrc="$EDITOR ~/.zshrc && source ~/.zshrc"

diff() { /usr/bin/diff --color=always "$@" | diff-so-fancy; }
lanip() { ip -o route get to 8.8.8.8 | sed -E "s/.*src ([0-9.]+).*/\\1/"; }
wanip() { curl ifconfig.me && echo; }
man() { /usr/bin/man "$@" | col -bx | bat -pl man; }
shperf() { zmodload zsh/zprof; "$@"; zprof; }

autocomplete() {
    eval "$1() { command $1 \"\$@\"; type __start_$1>/dev/null 2>&1 || . <(command $1 completion zsh); }"
}
autocomplete kubectl
autocomplete minikube
autocomplete helm
autocomplete skaffold

# zsh-autosuggestions slow paste fix
# https://github.com/zsh-users/zsh-autosuggestions/issues/238#issuecomment-389324292
pasteinit() {
    OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    zle -N self-insert url-quote-magic
}
pastefinish() {
    zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
EOF
)


ZSH_THEME=$(cat <<'EOF'
PROMPT='%{$fg_bold[green]%}%n@%m %{$fg[cyan]%}%1~ $(devsetup_git_prompt)'
RPROMPT='%(?:%{$fg_bold[green]%}✔:%? %{$fg[red]%}✘) %{$reset_color%} %*'

function devsetup_git_prompt() {
    local git_ps
    local ref
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
    git_ps="%{$fg_bold[blue]%}⌥ ${ref#refs/heads/}"

    local remote ahead behind git_remote_status git_remote_status_detailed
    remote=${$(command git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/}
    if [[ -n $remote ]]; then
        behind=$(command git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
        ahead=$(command git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
        if [[ $behind -gt 0 ]]; then
            git_ps+=" %{$fg[red]%}⏷$((behind))"
        fi
        if [[ $ahead -gt 0 ]]; then
            git_ps+=" %{$fg[green]%}⏶$((ahead))"
        fi
    fi

    local -a flags=('--porcelain' '--ignore-submodules=dirty')
    if [[ -n $(command git status $flags 2>/dev/null | tail -n1) ]]; then
        git_ps+=" %{$fg[yellow]%}✱"
    fi
    echo "$git_ps%{$reset_color%} "
}
EOF
)


# MAIN RUN
main "$@"
