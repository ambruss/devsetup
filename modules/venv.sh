is_installed() {
    test -d $VENV || return 1
    $VENV/bin/pip freeze | sed -E 's|([^=]+)=.*|\1|' >pip.list || return 1
    for PACKAGE in ${VENV_PACKAGES[@]}; do
        grep -q "^$PACKAGE\$" pip.list || return 1
    done
    return 0
}

install() {
    ! $FORCE || rm -rf $VENV
    PY_BIN=$(find /usr/local/bin -name 'python*' | grep -v config | sort | tail -n1)
    test -d $VENV || $PY_BIN -m venv $VENV
    $VENV/bin/pip install -U pip setuptools
    $VENV/bin/pip install -U "${VENV_PACKAGES[@]}"
    configure
}

configure() {
    $VENV/bin/ipython profile create
    sed_ipy() { sed -i "s|^#$1.*|$1 = $2|" ~/.ipython/profile_default/ipython_config.py; }
    sed_ipy c.InteractiveShellApp.extensions "['autoreload']"
    sed_ipy c.InteractiveShellApp.exec_lines "['%autoreload 2']"
    sed_ipy c.TerminalIPythonApp.display_banner False
    sed_ipy c.TerminalInteractiveShell.confirm_exit False
    sed_ipy c.TerminalInteractiveShell.editor "'nano'"
    sed_ipy c.TerminalInteractiveShell.term_title_format "'ipy {cwd}'"
    sed_ipy c.Completer.greedy True
    cat >~/.ipython/profile_default/startup/startup.py <<EOF
from requests import Session
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry


_retry_method_whitelist = ("DELETE", "GET", "HEAD", "POST", "PUT", "OPTIONS")
_retry_status_forcelist = (429, 500, 502, 503, 504)


class HTTPSession(Session):
    def __init__(
        self,
        baseurl="",
        headers=None,
        params=None,
        connect_timeout=5,
        read_timeout=15,
        retry_backoff_factor=0.5,
        retry_method_whitelist=_retry_method_whitelist,
        retry_status_forcelist=retry_status_forcelist,
        retry_total=3,
    ):
        super().__init__()
        self.baseurl = baseurl
        self.headers.update(headers or {})
        self.params.update(params or {})
        self.timeout = (connect_timeout, read_timeout)
        retry = Retry(
            backoff_factor=retry_backoff_factor,
            status_forcelist=retry_status_forcelist,
            method_whitelist=retry_method_whitelist,
            total=retry_total,
        )
        adapter = HTTPAdapter(max_retries=retry)
        self.mount("http://", adapter)
        self.mount("https://", adapter)

    def request(self, method, url, raw=False, **kwargs):
        kwargs.setdefault("timeout", self.timeout)
        response = super().request(method, f"{self.baseurl}{url}", **kwargs)
        if raw or kwargs.get("stream"):
            return response
        response.raise_for_status()
        try:
            return response.json()
        except:
            return response


chrome_ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36"
http = HTTPSession(headers={"User-Agent": chrome_ua})
EOF
}

VENV_PACKAGES=(
    ansible
    apscheduler
    arrow
    awscli
    bokeh
    bs4
    delorean
    dicomweb-client
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
    pre-commit
    psutil
    pydicom
    pyjq
    pynetdicom
    pynvim
    pyppeteer
    pyqt5
    pytest
    pytest-bandit
    pytest-black
    pytest-cov
    pytest-faker
    pytest-flake8
    pytest-isort
    pytest-mock
    pytest-mypy
    pytest-pylint
    python-dateutil
    pytimeparse
    pytz
    pyyaml
    requests
    requests-html
    scikit-learn
    scipy
    scrapy
    sh
    sqlalchemy
    typer[all]
    yamllint
    yapf
    yappi
    yq
)
