is_installed() {
    false
}

install() {
    test -n "$(gitconf --get user.name)" || (
        read -p "git user: " GIT_USER
        gitconf user.name "$GIT_USER"
    )

    test -n "$(gitconf --get user.email)" || (
        read -p "git email: " GIT_EMAIL
        gitconf user.email "$GIT_EMAIL"
    )

    gitconf alias.a     "add -p"
    gitconf alias.amend "commit -a --amend"
    gitconf alias.c     "commit"
    gitconf alias.cm    "commit -am"
    gitconf alias.co    "checkout"
    gitconf alias.cob   "checkout -b"
    gitconf alias.d     "diff"
    gitconf alias.dc    "diff --cached"
    gitconf alias.f     "fetch -p"
    gitconf alias.lg    "log --abbrev-commit --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
    gitconf alias.p     "push"
    gitconf alias.patch "!git --no-color --no-pager diff"
    gitconf alias.undo  "reset HEAD~1 --mixed"
    gitconf alias.alias "!git config --get-regexp ^alias\. | sed -E 's/^alias.//;s/ /\t= /'"

    gitconf core.pager  "diff-so-fancy | less --tabs=4 -RFX"
    gitconf diff-so-fancy.rulerWidth 47
    gitconf --bool diff-so-fancy.markEmptyLines false
    gitconf --bool diff-so-fancy.changeHunkIndicators false
    gitconf --bool diff-so-fancy.stripLeadingSymbols false

    gitconf color.ui true
    gitconf color.diff-highlight.oldNormal    "red bold"
    gitconf color.diff-highlight.oldHighlight "red bold 52"
    gitconf color.diff-highlight.newNormal    "green bold"
    gitconf color.diff-highlight.newHighlight "green bold 22"

    gitconf color.diff.meta       "yellow"
    gitconf color.diff.frag       "magenta bold"
    gitconf color.diff.commit     "yellow bold"
    gitconf color.diff.old        "red bold"
    gitconf color.diff.new        "green bold"
    gitconf color.diff.whitespace "red reverse"
}

gitconf() {
    git config --global "$@"
}
