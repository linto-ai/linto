#!/bin/bash

install_dialog() {
    if ! command -v dialog &>/dev/null; then
        echo "Installing dialog..."
        sudo apt-get install dialog -y
    fi

    if ! command -v dialog &>/dev/null; then
        echo "Error: dialog is not installed. Please install it to continue." >&2
        exit 1
    fi
}

install_jsonnet() {
    if ! command -v jsonnet &>/dev/null; then
        echo "Installing jsonnet..."
        sudo apt-get install jsonnet -y
    fi

    if ! dpkg -s apache2-utils &>/dev/null; then
        echo "Installing apache2-utils..."
        sudo apt-get install apache2-utils -y
    fi

    if ! command -v jq &>/dev/null; then
        echo "Installing jq..."
        sudo apt-get install jq -y
    fi

    if ! command -v yq &>/dev/null; then
        echo "Installing yq..."
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod a+x /usr/local/bin/yq
    fi
}

install_mkcert() {
    if ! command -v mkcert &>/dev/null; then
        echo "mkcert is not installed. Installing now..."

        sudo apt update
        sudo apt install -y libnss3-tools wget

        wget https://dl.filippo.io/mkcert/latest?for=linux/amd64 -O mkcert
        chmod +x mkcert
        sudo mv mkcert /usr/local/bin/

        mkcert -install

        echo "mkcert installed successfully"
    fi
}

install_dialog
install_jsonnet
install_mkcert
