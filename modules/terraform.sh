is_installed() {
    which terraform
}

install() {
    TF_VER=$(latest https://www.terraform.io/downloads.html terraform/$VERSION_RE)
    TF_URL=https://releases.hashicorp.com/terraform/$TF_VER/terraform_0.12.26_linux_amd64.zip
    curl -o terraform.zip $TF_URL
    unzip terraform.zip
    mv terraform $BIN
}
