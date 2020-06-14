is_installed() {
    which subl
}

install() {
    curl https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    echo "deb https://download.sublimetext.com/ apt/dev/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt-get -qq update
    sudo apt-get -qq install -y sublime-merge sublime-text
    SUBL_INSTALLS="$CONFIG/sublime-text-3/Installed Packages"
    SUBL_SETTINGS="$CONFIG/sublime-text-3/Packages/User"
    mkdir -p "$SUBL_INSTALLS" "$SUBL_SETTINGS"
    curl -O "https://packagecontrol.io/Package Control.sublime-package"
    mv "Package Control.sublime-package" "$SUBL_INSTALLS"
    configure
}


configure() {
cat <<EOF >"$SUBL_SETTINGS/Preferences.sublime-settings"
{
    "auto_complete_commit_on_tab": true,
    "color_scheme": "Packages/Color Scheme - Default/Monokai.sublime-color-scheme",
    "draw_white_space": "all",
    "ensure_newline_at_eof_on_save": true,
    "highlight_line": true,
    "remember_full_screen": true,
    "rulers": [88],
    "show_line_endings": true,
    "theme": "Adaptive.sublime-theme",
    "translate_tabs_to_spaces": true,
    "trim_trailing_white_space_on_save": true
}
EOF

cat <<EOF >"$SUBL_SETTINGS/Package Control.sublime-settings"
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
        "Package Control",
        "Python Fix Imports",
        "SideBarEnhancements",
        "sublack",
        "Sublime Tutor",
        "Terraform",
        "TrailingSpaces"
    ]
}
EOF

cat <<EOF >"$SUBL_SETTINGS/Anaconda.sublime-settings"
{
    "python_interpreter": "$VENV/bin/python"
}
EOF

cat <<EOF >"$SUBL_SETTINGS/MarkdownTableFormatter.sublime-settings"
{
    "autoformat_on_save": true
}
EOF

cat <<EOF >"$SUBL_SETTINGS/sublack.sublime-settings"
{
    "black_command": "$VENV/bin/black",
    "black_on_save": true
}
EOF

# TODO sidebar buttons disable
# TODO terraform format
# TODO python import sort

}
