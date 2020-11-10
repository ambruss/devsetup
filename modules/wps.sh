#!/usr/bin/env bash

is_installed() {
    cmd wps
}

install() {
    URL=$(get_wps_url)
    curl -O "$URL"
    sudo dpkg --install wps-office*.deb || sudo apt-get install -fqqy
    clone iamdh4/ttf-wps-fonts
    cdir ttf-wps-fonts
    sudo ./install.sh
}

get_wps_url() {
node <<'EOF'
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('https://linux.wps.com');

  const banner_btn = '#banner_btn';
  await page.waitForSelector(banner_btn);
  await page.click(banner_btn);

  const deb_btn = '#__download_link_deb__';
  await page.waitForSelector(deb_btn);
  const deb_url = await page.$eval(deb_btn, a => a.getAttribute('href'));
  console.log(deb_url);

  await browser.close();
})();
EOF
}
