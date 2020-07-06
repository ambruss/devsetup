#!/usr/bin/env bash

is_installed() {
    which jira
}

install() {
    JIRA_VER=$(latest go-jira/jira)
    JIRA_URL=https://github.com/go-jira/jira/releases/download/$JIRA_VER/jira-linux-amd64
    curl -o "$BIN/jira" "$JIRA_URL"
    chmod +x "$BIN/jira"
}
