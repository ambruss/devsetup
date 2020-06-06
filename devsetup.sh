#/usr/bin/env bash
export APPS="$(cat $0 2>/dev/null | grep -o '^should_install ([^ ]+)' | sed -E 's|.* (.*)|\1|' | sort)"
export APPS_VER="$(cat $0 2>/dev/null | grep -o 'arg_ver ([^ )]+)' | sed -E 's|.* (.*)|\1|' | sort)"
export USAGE="Usage: $0 [OPTION...]

Automated development environment and toolset setup on Elementary OS.

Examples:
  $0 --exclude sublime
  $0 --include python --version python=3.8.2 --force

Options:
  -i, --include APP         Only install explicitly whitelisted tools
  -x, --exclude APP         Skip installing explicitly blacklisted tools
  -v, --version APP=VER     Install tool version VER instead of latest
  -s, --secret KEY          Install licenses and keys using secret.sh
  -f, --force               Force tool re-installs even if already present
  -t, --dry-run             Only print what would be installed

$(if [ -n "$APPS" ]; then
echo "Tools supported via --include/--exclude:"
for APP in $APPS; do
    ENTRY="  - $APP"
    echo $APPS_VER | grep -q $APP && ENTRY="$ENTRY (supports -v)"
    echo "$ENTRY"
done
fi)
"

export VERSION_RE="v?[0-9]+(\.[0-9]+)+"  # common version regex

export INCLUDE=  # tools marked as included
export EXCLUDE=  # tools marked as excluded
export VERSION=  # version overrides
export SECRET=   # secret key file
export FORCE=false    # toggle forcing reinstalls
export DRY_RUN=false  # toggle dry-run

export CONFIG=$HOME/.config
export LOCAL=$HOME/local
export BIN=$LOCAL/bin
export SHARE=$LOCAL/share
export NODE=$LOCAL/node
export VENV=$LOCAL/venv


# MAIN BEGIN
main() {

test "$DEBUG" && set -o xtrace
set -o errexit
set -o nounset
test $(id -un) = root && log "Cannot run as root" && exit 1

while [ $# -gt 0 ]; do
    case $1 in
        -i|--include) INCLUDE="$INCLUDE $2"; shift;;
        -x|--exclude) EXCLUDE="$EXCLUDE $2"; shift;;
        -v|--version) VERSION="$VERSION $2"; shift;;
        -s|--secret) SECRET="$2"; shift;;
        -f|--force) FORCE=true;;
        -t|--dry-run) DRY_RUN=true;;
        -h|--help) printf "$USAGE"; exit 0;;
        *) printf "Unkown arg: $1\n\n$USAGE" >&2; exit 1;;
    esac
    shift
done

cd /tmp
mkdir -p $CONFIG $BIN $SHARE
export PATH=$BIN:$PATH

should_install apt-packages is_installed_apt && (
sudo apt-get -qq update
sudo apt-get -qq install -y $APT_PACKAGES
printf "[User]\nSystemAccount=true\n" | sudo tee /var/lib/AccountsService/users/libvirt-qemu
sudo systemctl restart accounts-daemon.service
)

lsmod | grep -q vhost || (
log "Enabling vhost_net module"
sudo modprobe vhost_net
echo vhost_net | sudo tee -a /etc/modules
)

DISPLAYLINK_CONF=/usr/share/X11/xorg.conf.d/20-displaylink.conf
should_install displaylink "test -f $DISPLAYLINK_CONF" && (
DISPLAYLINK_SITE=https://www.displaylink.com
DISPLAYLINK_FILE=$(latest $DISPLAYLINK_SITE/downloads/ubuntu "/downloads/file\?id=\d+" | grep -o "\d+")
DISPLAYLINK_URL="$DISPLAYLINK_SITE/downloads/file?id=$DISPLAYLINK_FILE"
curl -o displaylink.zip -d"fileId=$DISPLAYLINK_FILE&accept_submit=Accept" $DISPLAYLINK_URL
unzip displaylink.zip
sudo ./displaylink-driver*.run
sudo cat <<EOF >$DISPLAYLINK_CONF
Section "Device"
  Identifier "DisplayLink"
  Driver "modesetting"
  Option "PageFlip" "false"
EndSection
EOF
)

should_install virtualbox && (
VBOX_URL=$(curl https://www.virtualbox.org/wiki/Linux_Downloads \
    | grep "All distributions" | grep -o "https://.*run")
VBOX_EXTPACK_URL=$(curl https://www.virtualbox.org/wiki/Downloads \
    | grep "All supported platforms" | grep -o "https://.*extpack")
curl -o vbox.run $VBOX_URL
chmod +x vbox.run
sudo ./vbox.run
curl -O $VBOX_EXTPACK_URL
yes | sudo VBoxManage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack*
)

log "Configuring git"
gitconf() { git config --global "$@"; }
gitconf alias.a "add -p"
gitconf alias.amend "commit -a --amend"
gitconf alias.c "commit"
gitconf alias.cm "commit -am"
gitconf alias.co "checkout"
gitconf alias.cob "checkout -b"
gitconf alias.d "diff"
gitconf alias.dc "diff --cached"
gitconf alias.f "fetch -p"
gitconf alias.lg "log --abbrev-commit --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
gitconf alias.p "push"
gitconf alias.patch "!git --no-color --no-pager diff"
gitconf alias.undo "reset HEAD~1 --mixed"
gitconf alias.alias "!git config --get-regexp ^alias\. | sed -E 's/^alias.//;s/ /\t= /'"

if [ -z "$(gitconf --get user.name)" ]; then
    printf "git user: "
    read GIT_USER
    gitconf user.name "$GIT_USER"
fi
if [ -z "$(gitconf --get user.email)" ]; then
    printf "git email: "
    read GIT_EMAIL
    gitconf user.email "$GIT_EMAIL"
fi

should_install git-crypt && (
test -d $SHARE/git-crypt || git clone https://github.com/AGWA/git-crypt.git $SHARE/git-crypt
cd $SHARE/git-crypt
make
make install PREFIX=$LOCAL
)

test -n "$SECRET" && (
test -d $SHARE/devsetup || git clone https://github.com/ambruss/devsetup.git $SHARE/devsetup
cd $SHARE/devsetup
git-crypt unlock $SECRET
. ./secret.sh
)

which zsh >/dev/null && getent passwd $(id -u) | grep -q zsh || (
log "Setting user shell to zsh"
chsh -s $(which zsh)
)

should_install oh-my-zsh "test -d ~/.oh-my-zsh" && (
rm -rf ~/.oh-my-zsh
OHMYZSH_DIR=~/.oh-my-zsh/custom
OHMYZSH_URL=https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
OHMYZSH_THEME_URL=https://raw.githubusercontent.com/jackharrisonsherlock/common/master/common.zsh-theme
curl $OHMYZSH_URL | sh
curl -o $OHMYZSH_DIR/custom/themes/common.zsh-theme $OHMYZSH_THEME_URL
(
    cd $OHMYZSH_DIR/plugins
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git
)
sed_zshrc() { sed -i "s|$1|$2|" ~/.zshrc; }
sed_zshrc 'ZSH_THEME="robbyrussell"'       'ZSH_THEME="common"'
sed_zshrc '# DISABLE_UPDATE_PROMPT="true"' 'DISABLE_UPDATE_PROMPT="true"'
sed_zshrc '# HIST_STAMPS="mm/dd/yyyy"'     'HIST_STAMPS="yyyy-mm-dd"'
sed_zshrc '^plugins=.*' 'plugins=(extract git httpie z zsh-autosuggestions zsh-syntax-highlighting)'
echo "$ZSH_PROFILE" | sed "s|{{PATH}}|$VENV/bin:$NODE/bin:$BIN|" >$OHMYZSH_DIR/devsetup.zsh
touch ~/.z
)

should_install nanorc "test -f ~/.nanorc" && (
NANORC_URL=https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh
curl $NANORC_URL | sh
find ~/.nano -type f | xargs sed -i "s/normal/white/g"
echo "$NANORC" >>~/.nanorc
)

should_install elementary-tweaks "apt show elementary-tweaks" && (
sudo add-apt-repository -y ppa:philip.scott/elementary-tweaks
sudo apt-get -qq install -y elementary-tweaks
)

should_install google-chrome && (
curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg --install google-chrome-stable_current_amd64.deb || sudo apt-get install -yf
)

should_install slack && (
curl -O https://downloads.slack-edge.com/linux_releases/slack-desktop-4.3.2-amd64.deb
sudo dpkg --install slack-desktop-*.deb || sudo apt-get install -fy
)

should_install miktex && (
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
echo "deb http://miktex.org/download/ubuntu bionic universe" | sudo tee /etc/apt/sources.list.d/miktex.list
sudo apt-get -qq update
sudo apt-get -qq install -y miktex
miktexsetup --user-link-target-directory="$BIN" finish
initexmf --set-config-value "[MPM]AutoInstall=1"
)

should_install sublime "which subl" && (
curl https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/dev/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get -qq update
sudo apt-get -qq install -y sublime-merge sublime-text
SUBL_INSTALLS="$CONFIG/sublime-text-3/Installed Packages"
SUBL_SETTINGS="$CONFIG/sublime-text-3/Packages/User"
mkdir -p "$SUBL_INSTALLS" "$SUBL_SETTINGS"
curl -O "https://packagecontrol.io/Package Control.sublime-package"
mv "Package Control.sublime-package" "$SUBL_INSTALLS"
echo "$SUBL_PACKAGES" >"$SUBL_SETTINGS/Package Control.sublime-settings"
echo "$SUBL_PREFERENCES" >"$SUBL_SETTINGS/Preferences.sublime-settings"
echo "$SUBL_ANACONDA" >"$SUBL_SETTINGS/Anaconda.sublime-settings"
echo "$SUBL_BLACK" >"$SUBL_SETTINGS/sublack.sublime-settings"
echo "$SUBL_MARKDOWNTABLE" >"$SUBL_SETTINGS/MarkdownTableFormatter.sublime-settings"
)

should_install pandoc && (
PANDOC_VER=$(latest jgm/pandoc)
PANDOC_DEB=pandoc-$PANDOC_VER-1-amd64.deb
PANDOC_URL=https://github.com/jgm/pandoc/releases/download/$PANDOC_VER/$PANDOC_DEB
curl -O $PANDOC_URL
sudo dpkg --install $PANDOC_DEB || sudo apt-get install -yf
# TODO first-run
)

should_install nvim && (
NVIM_VER=$(latest neovim/neovim)
NVIM_URL=https://github.com/neovim/neovim/releases/download/$NVIM_VER/nvim.appimage
curl -o $BIN/nvim $NVIM_URL
chmod +x $BIN/nvim
rm -rf $CONFIG/nvim $SHARE/nvim
curl -O https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p $CONFIG/nvim $SHARE/nvim/site/autoload
mv -f plug.vim $SHARE/nvim/site/autoload
echo "$INIT_VIM" >$CONFIG/nvim/init.vim
)

should_install bat && (
BAT_VER=$(latest sharkdp/bat)
BAT_DIR=bat-$BAT_VER-x86_64-unknown-linux-gnu
BAT_URL=https://github.com/sharkdp/bat/releases/download/$BAT_VER/$BAT_DIR.tar.gz
curl $BAT_URL | tar xz
mv -f $BAT_DIR/bat $BIN
)

should_install exa && (
EXA_VER=$(latest ogham/exa)
EXA_BIN=exa-linux-x86_64
EXA_ZIP=$EXA_BIN-$(echo $EXA_VER | sed 's|v||').zip
EXA_URL=https://github.com/ogham/exa/releases/download/$EXA_VER/$EXA_ZIP
curl -O $EXA_URL
unzip $EXA_ZIP
mv -f $EXA_BIN $BIN/exa
)

should_install jq && (
JQ_VER=$(latest stedolan/jq)
JQ_URL=https://github.com/stedolan/jq/releases/download/$JQ_VER/jq-linux64
curl -o $BIN/jq $JQ_URL
chmod +x $BIN/jq
)

should_install rg && (
RG_VER=$(latest BurntSushi/ripgrep)
RG_DIR=ripgrep-$RG_VER-x86_64-unknown-linux-musl
RG_URL=https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/$RG_DIR.tar.gz
curl $RG_URL | tar xz
mv -f $RG_DIR/rg $BIN
)

should_install fd && (
FD_VER=$(latest sharkdp/fd)
FD_DIR=fd-$FD_VER-x86_64-unknown-linux-gnu
FD_URL=https://github.com/sharkdp/fd/releases/download/$FD_VER/$FD_DIR.tar.gz
curl $FD_URL | tar xz
mv -f $FD_DIR/fd $BIN
)

should_install fzf && (
rm -rf $SHARE/fzf
git clone --depth 1 https://github.com/junegunn/fzf.git $SHARE/fzf
sudo $SHARE/fzf/install --all --no-bash
)

should_install jira && (
JIRA_VER=$(latest go-jira/jira)
JIRA_URL=https://github.com/go-jira/jira/releases/download/$JIRA_VER/jira-linux-amd64
curl -o $BIN/jira $JIRA_URL
chmod +x $BIN/jira
)

should_install diff-so-fancy && (
DIFF_URL=https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
curl -o $BIN/diff-so-fancy $DIFF_URL
chmod +x $BIN/diff-so-fancy
eval $(diff-so-fancy --colors)
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
git config --global --bool diff-so-fancy.markEmptyLines false
git config --global --bool diff-so-fancy.changeHunkIndicators false
git config --global --bool diff-so-fancy.stripLeadingSymbols false
git config --global diff-so-fancy.rulerWidth 47
)

PY_VER=$(arg_ver python || latest https://www.python.org/downloads/ "Python ($VERSION_RE)")
PY_URL=https://www.python.org/ftp/python/$PY_VER/Python-$PY_VER.tar.xz
PY_BIN=$(echo python$PY_VER | sed 's/\.[0-9]$//')
should_install python "which $PY_BIN" && (
curl $PY_URL | tar xJ
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
)
)

should_install venv "test -d $VENV" && (
which virtualenv || sudo python -m pip install virtualenv
rm -rf $VENV
virtualenv -p $PY_BIN $VENV
)

should_install pip-packages is_installed_pip && (
$VENV/bin/pip install $PIP_PACKAGES
CHROMIUM_URL=https://storage.googleapis.com/chromium-browser-snapshots/Linux_x64/LAST_CHANGE
PYPPETEER_CHROMIUM_REVISION=$(curl $CHROMIUM_URL) \
$VENV/bin/pyppeteer-install
$VENV/bin/ipython profile create
sed_ipy() { sed -i "s|^#$1.*|$1 = $2|" ~/.ipython/profile_default/ipython_config.py; }
# TODO import pretty-print as pp
sed_ipy c.InteractiveShell.autocall 0
sed_ipy c.InteractiveShellApp.extensions "['autoreload']"
sed_ipy c.InteractiveShellApp.exec_lines "['%autoreload 2']"
sed_ipy c.TerminalIPythonApp.display_banner False
sed_ipy c.TerminalInteractiveShell.confirm_exit False
sed_ipy c.TerminalInteractiveShell.editor "'nano'"
sed_ipy c.TerminalInteractiveShell.term_title_format "'ipy {cwd}'"
sed_ipy c.Completer.greedy True
)

should_install node "test -d $NODE" && (
NODE_VER=$(latest https://nodejs.org/dist/latest/ "-($VERSION_RE)-")
NODE_DIR=node-$NODE_VER-linux-x64
NODE_URL=https://nodejs.org/dist/latest/$NODE_DIR.tar.xz
curl $NODE_URL | tar xJ
rm -rf $NODE
mv -f $NODE_DIR $NODE
PATH="$NODE/bin:$PATH" NPM_CONFIG_PREFIX=$NODE npm install --global tldr
)

should_install docker && (
curl https://get.docker.com | env -i sh
sudo usermod -aG docker $(id -un)
)

should_install docker-machine && (
DMACHINE_VER=$(latest docker/machine)
DMACHINE_URL=https://github.com/docker/machine/releases/download/$DMACHINE_VER/docker-machine-Linux-x86_64
curl -o $BIN/docker-machine $DMACHINE_URL
chmod +x $BIN/docker-machine
)

should_install kubectl && (
KUBE_VER=$(arg_ver kubectl || curl https://storage.googleapis.com/kubernetes-release/release/stable.txt)
KUBE_URL=https://storage.googleapis.com/kubernetes-release/release/$KUBE_VER/bin/linux/amd64/kubectl
curl -o $BIN/kubectl $KUBE_URL
chmod +x $BIN/kubectl
)

should_install helm && (
HELM_VER=$(arg_ver helm || latest helm/helm "-($VERSION_RE)-")
HELM_URL=https://get.helm.sh/helm-$HELM_VER-linux-amd64.tar.gz
curl $HELM_URL | tar xz
mv -f linux-amd64/helm $BIN
)

should_install skaffold && (
SKAFFOLD_VER=$(latest GoogleContainerTools/skaffold)
SKAFFOLD_URL=https://github.com/GoogleContainerTools/skaffold/releases/download/$SKAFFOLD_VER/skaffold-linux-amd64
curl -o $BIN/skaffold $SKAFFOLD_URL
chmod +x $BIN/skaffold
)

should_install minikube && (
MINIKUBE_VER=$(latest kubernetes/minikube)
MINIKUBE_BASEURL=https://github.com/kubernetes/minikube/releases/download/$MINIKUBE_VER
curl -o $BIN/minikube $MINIKUBE_BASEURL/minikube-linux-amd64
curl -o $BIN/docker-machine-driver-kvm2 $MINIKUBE_BASEURL/docker-machine-driver-kvm2
chmod +x $BIN/minikube $BIN/docker-machine-driver-kvm2
minikube config set cpus 2
minikube config set disk-size 32768
minikube config set memory 4096
minikube config set vm-driver kvm2
minikube config set WantNoneDriverWarning false
minikube config set WantUpdateNotification false
KUBE_VER=$(kubectl version 2>/dev/null | grep -o $VERSION_RE | head -1)
test -n "$KUBE_VER" && minikube config set kubernetes-version $KUBE_VER
)

log "Devsetup complete"
return 0

# MAIN END
}


# log message line with colored info prefix
log() { printf "\e[32m[INFO]\e[0m %s\n" "$*"; }

# use defaults on the basic tools
curl() { command curl -fLSs --retry 3 --connect-timeout 1 "$@"; }
grep() { command grep -P "$@"; }
sed() { command sed -E "$@"; }


# get and maintain sudo
export SUDO_ENABLED=false
sudo() {
    if ! $SUDO_ENABLED; then
        command sudo true
        keep_sudo() {(
            set +x
            sleep 60
            command sudo -n true
            kill -0 "$$" 2>/dev/null || exit
        )}
        while true; do
            keep_sudo
        done &
        SUDO_ENABLED=true
    fi
    command sudo "$@"
}


# get latest version from a release page
latest() {
    local REPO="$1"
    local RE="${2:-/($VERSION_RE)/}"
    echo $REPO | grep -q "^http" || REPO=https://github.com/$REPO/releases
    curl $REPO | grep -o "href.*$RE" | grep -o -- "$VERSION_RE" | head -n1
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
    if $FORCE || ! eval "$IS_INSTALLED" >/dev/null 2>&1; then
        log "Installing $TOOL"
        $DRY_RUN && return 1 || return 0
    fi
    return 1
}


# return 0 if all packages in APT_PACKAGES are installed
is_installed_apt() {
    apt list --installed 2>/dev/null | sed -E 's|([^/]+)/.*|\1|' >apt.list
    for PACKAGE in $APT_PACKAGES; do
        grep -q "^$PACKAGE\$" apt.list || return 1
    done
    return 0
}


# return 0 if all packages in PIP_PACKAGES are installed
is_installed_pip() {
    pip freeze | sed -E 's|([^=]+)=.*|\1|' >pip.list || return 1
    for PACKAGE in $PIP_PACKAGES; do
        grep -q "^$PACKAGE\$" pip.list || return 1
    done
    return 0
}


# echo tool version specified by the user, if any
arg_ver() {
    local TOOL="$1"
    local TOOL_VER=$(echo $VERSION | grep $TOOL= | sed "s|.*$TOOL=($VERSION_RE).*|\1|")
    test $TOOL_VER || return 1
    echo $TOOL_VER
}


APT_PACKAGES=$(cat <<EOF
apt-transport-https
autoconf
automake
bridge-utils
build-essential
curl
dkms
dmg2img
dstat
git
htop
libbz2-dev
libguestfs-tools
libncurses5-dev
libncursesw5-dev
libreadline-dev
libsqlite3-dev
libssl-dev
libtool
libvirt-bin
llvm
nano
ncdu
qemu
qemu-kvm
software-properties-common
tmux
tree
uml-utilities
virt-manager
virt-top
virtinst
wget
xclip
xsltproc
xz-utils
zlib1g-dev
zsh
EOF
)


PIP_PACKAGES=$(cat <<EOF
ansible
apscheduler
arrow
black
bokeh
bs4
delorean
docker-compose
fastapi
fuzzywuzzy[speedup]
httpie
invoke
ipython
jedi
keras
matplotlib
numpy
pandas
pandoc
pendulum
pillow
pip-compile-multi
pipenv
poetry
psutil
pyjq
pynvim
pyqt5
pytest
pytest-bandit
pytest-cov
pytest-faker
pytest-flake8
pytest-mock
pytest-mypy
pytest-pylint
python-dateutil
pytz
pyyaml
pyppeteer
requests
requests-html
scikit-learn
scipy
scrapy
sh
sqlalchemy
typer[all]
yapf
yappi
yq
EOF
)


SUBL_PACKAGES=$(cat <<EOF
{
    "installed_packages":
    [
        "A File Icon",
        "All Autocomplete",
        "Anaconda",
        "AutoFileName",
        "BracketHighlighter",
        "Dockerfile Syntax Highlighting",
        "GitGutter",
        "Markdown Extended",
        "Markdown Table Formatter",
        "MarkdownTOC",
        "nginx",
        "SideBarEnhancements",
        "sublack"
        "Sublime Tutor",
        "TrailingSpaces"
    ]
}
EOF
)


SUBL_PREFERENCES=$(cat <<EOF
{
    "auto_complete_commit_on_tab": true,
    "color_scheme": "Packages/Color Scheme - Default/Monokai.sublime-color-scheme",
    "draw_white_space": "all",
    "ensure_newline_at_eof_on_save": true,
    "highlight_line": true,
    "remember_full_screen": true,
    "rulers": [80, 100],
    "show_line_endings": true,
    "theme": "Adaptive.sublime-theme",
    "translate_tabs_to_spaces": true,
    "trim_trailing_white_space_on_save": true
}
EOF
)


SUBL_ANACONDA=$(cat <<EOF
{
    "python_interpreter": "$VENV/bin/python"
}
EOF
)

SUBL_BLACK=$(cat <<EOF
{
    "black_command": "$VENV/bin/black",
    "black_on_save": true
}
EOF
)

SUBL_MARKDOWNTABLE=$(cat <<EOF
{
    "autoformat_on_save": true
}
EOF
)


INIT_VIM=$(cat <<EOF
call plug#begin('$SHARE/nvim/plugged')
Plug 'davidhalter/jedi-vim', {'do': ':UpdateRemotePlugins'}
Plug 'jiangmiao/auto-pairs', {'do': ':UpdateRemotePlugins'}
Plug 'machakann/vim-highlightedyank', {'do': ':UpdateRemotePlugins'}
Plug 'neomake/neomake', {'do': ':UpdateRemotePlugins'}
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
Plug 'sbdchd/neoformat', {'do': ':UpdateRemotePlugins'}
Plug 'scrooloose/nerdcommenter', {'do': ':UpdateRemotePlugins'}
Plug 'scrooloose/nerdtree', {'do': ':UpdateRemotePlugins'}
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'terryma/vim-multiple-cursors', {'do': ':UpdateRemotePlugins'}
Plug 'tmhedberg/SimpylFold', {'do': ':UpdateRemotePlugins'}
Plug 'vim-airline/vim-airline', {'do': ':UpdateRemotePlugins'}
Plug 'vim-airline/vim-airline-themes', {'do': ':UpdateRemotePlugins'}
Plug 'zchee/deoplete-jedi', {'do': ':UpdateRemotePlugins'}
call plug#end()
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
let g:airline_theme='minimalist'
let g:deoplete#auto_complete_delay = 100
let g:deoplete#enable_at_startup = 1
set splitbelow
EOF
)


NANORC=$(cat <<EOF
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


# TODO help
ZSH_PROFILE=$(cat <<'EOF'
setopt autocd autopushd pushdignoredups

export DOCKER_BUILDKIT=1
export EDITOR=nano
export MINIKUBE_IN_STYLE=false
export NPM_CONFIG_PREFIX=$NODE
export PAGER="less -RF"
export PATH={{PATH}}:$PATH
export PIPENV_HIDE_EMOJIS=1
export REPORTMEMORY=10240
export REPORTTIME=5
export TIMEFMT="$TIMEFMT mem %M"

alias cat="bat"
alias d="dirs -v | head -5"
alias grep="grep --color=auto --perl-regexp \
    --exclude={.coverage} \
    --exclude-dir={.git,.npm,node_modules,htmlcov}"
alias ls="exa -ahl --git --group-directories-first --time-style=long-iso"
alias tldr="tldr -t base16"
alias top="htop"
alias tree="tree --dirsfirst --sort=version"
alias zshrc="$EDITOR ~/.zshrc && source ~/.zshrc"

alias c="xclip"
alias v="xclip -o"

alias encrypt="gpg --armor --symmetric"
alias decrypt="gpg"

diff() { /usr/bin/diff --color=always "$@" | diff-so-fancy; }
lanip() { ip -o route get to 8.8.8.8 | sed -E "s/.*src ([0-9.]+).*/\\1/"; }
wanip() { curl ifconfig.me && echo; }
man() { /usr/bin/man "$@" | col -bx | bat -pl man; }
shperf() { zmodload zsh/zprof; "$@"; zprof; }

# lazy-load autocomplete scripts
autocomplete() {
    local CMD="$1"                          # command to autocomplete
    local COMP_ARGS="${2:-completion zsh}"  # cmd args for printing completion
    local COMP_FUNC="${3:-__start_$CMD}"    # the completion fn name
    # shadow cmd to load completion after first use
    eval "$1() {
        command $CMD \"\$@\"
        type $COMP_FUNC >/dev/null 2>&1 || . <(command $CMD $COMP_ARGS)
    }"
}
autocomplete jira --completion-script-zsh _jira_bash_autocomplete
autocomplete pip "completion --zsh" _pip_completion
autocomplete pipenv --completion _pipenv
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


# MAIN RUN
main "$@"
