#!/bin/bash

set -uea
SUDO=''
if [ -f ".env" ]; then
    . .env
else
    . .envdefault
fi
RUNNING_DIR="./running"

CONFIG_TEMPLATES="./conf-templates"
CERTS_DIR="${LINTO_SHARED_MOUNT}/certs-mkcert"

#!/bin/bash
cleanup() {
    find $RUNNING_DIR -type l -exec rm {} \;
    rm -f "$RUNNING_DIR/.dockerenv"
}

clear_yaml() {
    rm -f "$RUNNING_DIR"/*.yaml
}

# TODO: Make sure to check the user SECURES mode
cleanup
clear_yaml

sudo ./scripts/dependencies.sh
./scripts/setup-services.sh
