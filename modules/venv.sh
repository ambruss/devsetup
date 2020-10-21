#!/usr/bin/env bash

is_installed() {
    test -d "$VENV" || return 1
    "$VENV/bin/pip" freeze | sed -E 's|([^=]+)=.*|\1|' >pip.list || return 1
    for PACKAGE in "${VENV_PACKAGES[@]}"; do
        grep -q "^$PACKAGE\$" pip.list || return 1
    done
    return 0
}

install() {
    ! $FORCE || rm -rf "$VENV"
    PY_BIN=$(find /usr/local/bin -name 'python*' | grep -v config | sort | tail -n1)
    test -d "$VENV" || "$PY_BIN" -m venv "$VENV"
    "$VENV/bin/pip" install -U pip setuptools wheel
    "$VENV/bin/pip" install -U "${VENV_PACKAGES[@]}"
    configure
}

configure() {
    "$VENV/bin/ipython" profile create
    sed_ipy() { sed -i "s|^# ?$1.*|$1 = $2|" ~/.ipython/profile_default/ipython_config.py; }
    sed_ipy c.InteractiveShellApp.extensions "['autoreload']"
    sed_ipy c.InteractiveShellApp.exec_lines "['%autoreload 2']"
    sed_ipy c.TerminalIPythonApp.display_banner False
    sed_ipy c.TerminalInteractiveShell.confirm_exit False
    sed_ipy c.TerminalInteractiveShell.editor "'nano'"
    sed_ipy c.TerminalInteractiveShell.term_title_format "'ipy {cwd}'"
    sed_ipy c.Completer.greedy True
}

VENV_PACKAGES=(
    "ansible"
    "apscheduler"
    "arrow"
    "asciinema"
    "awscli"
    "black"
    "bokeh"
    "bs4"
    "delorean"
    "dicomweb-client"
    "docker-compose"
    "fastapi"
    "flake8"
    "flake8-bugbear"
    "fuzzywuzzy[speedup]"
    "httpie"
    "invoke"
    "ipython"
    "isort"
    "jedi"
    "keras"
    "matplotlib"
    "mypy"
    "numpy"
    "pandas"
    "pandoc"
    "pendulum"
    "pillow"
    "pip-compile-multi"
    "pipenv"
    "poetry"
    "pre-commit"
    "psutil"
    "pydicom"
    "pyjq"
    "pylint"
    "pynetdicom"
    "pynvim"
    "pyppeteer"
    "pyqt5"
    "pytest"
    "pytest-cov"
    "pytest-faker"
    "pytest-mock"
    "pytest-testmon"
    "pytest-watch"
    "python-dateutil"
    "pytimeparse"
    "pytz"
    "pyyaml"
    "requests"
    "requests-html"
    "scikit-learn"
    "scipy"
    "scrapy"
    "sh"
    "sqlalchemy"
    "typer[all]"
    "yamllint"
    "yapf"
    "yappi"
    "yq"
)
