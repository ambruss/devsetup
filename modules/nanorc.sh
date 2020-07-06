#!/usr/bin/env bash

is_installed() {
    test -f ~/.nanorc
}

install() {
    NANORC_URL=https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh
    curl "$NANORC_URL" | sh
    find ~/.nano -type f -print0 | xargs --null sed -i "s/normal/white/g"
    echo "$NANORC" >>~/.nanorc
}

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
