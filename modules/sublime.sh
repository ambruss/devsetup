#!/usr/bin/env bash

is_installed() {
    cmd subl
}

install() {
    curl https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    sudo apt-add-repository "deb https://download.sublimetext.com/ apt/dev/"
    sudo apt-get update -qq
    sudo apt-get install -qqy sublime-merge sublime-text
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
        "KeybindingHelper",
        "Markdown Extended",
        "Markdown Table Formatter",
        "MarkdownTOC",
        "nginx",
        "Package Control",
        "Python Fix Imports",
        "SideBarEnhancements",
        "sublack",
        "Sublime Tutor",
        "Terminus",
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

cat <<EOF >"$SUBL_SETTINGS/Side Bar.sublime-settings"
{
    "confirm_before_deleting": false,
    "confirm_before_permanently_deleting": false,
    "disabled_menuitem_edit": true,
    "disabled_menuitem_edit_to_right": true,
    "disabled_menuitem_open_run": true,
    "disabled_menuitem_open_in_browser": true,
    "disabled_menuitem_open_in_new_window": true,
    "disabled_menuitem_copy_name": true,
    "disabled_menuitem_copy_path": true,
    "disabled_menuitem_copy_path_windows": true,
    "disabled_menuitem_copy_dir_path": true,
    "disabled_menuitem_paste_in_parent": true,
    "disabled_menuitem_empty": true,
    "disabled_menuitem_folder_save": true,
    "disabled_menuitem_folder_close": true,
    "default_browser": "chrome",
    "disable_send_to_trash": true,
    "i_donated_to_sidebar_enhancements_developer": "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=DD4SL2AHYJGBW"
}
EOF

cat <<EOF >"$SUBL_SETTINGS/sublack.sublime-settings"
{
    "black_command": "$VENV/bin/black",
    "black_on_save": true
}
EOF

cat <<EOF >"$SUBL_SETTINGS/Terminus.sublime-settings"
{
    "256color": true,
    "unix_term": "xterm-256color",
    "theme": "monokai"
}
EOF

cat <<EOF >"$SUBL_SETTINGS/trailing_spaces.sublime-settings"
{
    "trim_on_save": true
}
EOF

}
