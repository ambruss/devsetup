#!/usr/bin/env bash

is_installed() {
    cmd minikube
}

install() {
    MINIKUBE_VER=$(latest kubernetes/minikube)
    MINIKUBE_BASEURL=https://github.com/kubernetes/minikube/releases/download/$MINIKUBE_VER
    curl -o "$BIN/minikube" "$MINIKUBE_BASEURL/minikube-linux-amd64"
    curl -o "$BIN/docker-machine-driver-kvm2" "$MINIKUBE_BASEURL/docker-machine-driver-kvm2"
    chmod +x "$BIN/minikube" "$BIN/docker-machine-driver-kvm2"
    minikube config set cpus 2
    minikube config set disk-size 32768
    minikube config set memory 4096
    minikube config set vm-driver kvm2
    minikube config set WantNoneDriverWarning false
    minikube config set WantUpdateNotification false
    KUBE_VER=$(kubectl version 2>/dev/null | grep -o "$VERSION_RE" | head -n1 || true)
    minikube config set kubernetes-version "$KUBE_VER"
}
