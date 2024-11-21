#!/bin/bash
set -uea
SUDO=''
if [ -f ".env" ]; then
    source .env
else
    source .envdefault
fi

CONFIG_TEMPLATES="./conf-templates"
CERTS_DIR="${LINTO_SHARED_MOUNT}/certs-mkcert"

create_networks() {
    # $1 : network names to create (comma-separated string)
    if [[ -z "$1" ]]; then
        echo "No network names provided. Exiting."
        return 1
    fi

    # Convert the comma-separated string to an array
    IFS=',' read -r -a networks <<<"$1"

    for network in "${networks[@]}"; do
        network=$(echo "$network" | xargs)

        # Check if the network already exists
        if docker network inspect "$network" >/dev/null 2>&1; then
            echo "Network '$network' already exists. Skipping."
        else
            docker network create \
                -d overlay \
                --attachable \
                "$network"
            echo "Network '$network' created."
        fi
    done
}

build_stt() {
    echo "Building STT..."

    mkdir -p ${LINTO_LOCAL_MOUNT}/database/db-stt-services-data \
        ${LINTO_SHARED_MOUNT}/audios/api_uploads \
        ${LINTO_SHARED_MOUNT}/redis/ \
        ${LINTO_SHARED_MOUNT}/models/ \
        ${LINTO_SHARED_MOUNT}/qdrant_storage/

    envsubst <"$CONFIG_TEMPLATES/redis/redis.conf" >"${LINTO_SHARED_MOUNT}/redis/redis.conf"
    create_networks "net_stt_services,task_broker_services"
}

build_llm() {
    echo "Building LLM..."

    mkdir -p "${LINTO_SHARED_MOUNT}/llm_services/" \
        ${LINTO_SHARED_MOUNT}/models/
    cp -r "${CONFIG_TEMPLATES}/llm/"* "${LINTO_SHARED_MOUNT}/llm_services/"

    create_networks "net_llm_services"
}

build_studio() {
    echo "Building Studio..."

    mkdir -p ${LINTO_LOCAL_MOUNT}/database/db-cm-data \
        ${LINTO_SHARED_MOUNT}/conversation-manager/audios/original/ \
        ${LINTO_SHARED_MOUNT}/conversation-manager/pictures/ \
        ${LINTO_SHARED_MOUNT}/conversation-manager/audiowaveform/
    sudo cp -r "${CONFIG_TEMPLATES}/studio/pictures/"* "${LINTO_SHARED_MOUNT}/conversation-manager/pictures/" >/dev/null

    # Special permission for studio image (not run in owner)
    sudo chown -R 1000:1000 ${LINTO_SHARED_MOUNT}/conversation-manager/audios/
    sudo chown -R 1000:1000 ${LINTO_SHARED_MOUNT}/conversation-manager/pictures/
    sudo chown -R 1000:1000 ${LINTO_SHARED_MOUNT}/conversation-manager/audiowaveform/

    create_networks "net_studio,session_network"
}

build_traefik() {
    echo "Building Traefik..."
    output_file="${LINTO_SHARED_MOUNT}/traefik/traefik.toml"

    sudo rm -rf ${LINTO_LOCAL_MOUNT}/traefik/
    mkdir -p ${LINTO_SHARED_MOUNT}/traefik/ \
        ${LINTO_LOCAL_MOUNT}/traefik/logs \
        ${LINTO_SHARED_MOUNT}/certs/ \
        ${CERTS_DIR}

    sudo touch ${LINTO_SHARED_MOUNT}/certs/acme.json
    sudo chmod 600 ${LINTO_SHARED_MOUNT}/certs/acme.json
    sudo chown -R root:root ${LINTO_LOCAL_MOUNT}/traefik

    create_networks "$DOCKER_NETWORK,linto-saas"

    LINTO_HTTP_HASH_STRING=$(htpasswd -nb ${LINTO_HTTP_USER} ${LINTO_HTTP_PASSWORD})
    export LINTO_HTTP_HASH_STRING

    envsubst <"$CONFIG_TEMPLATES/traefik/dynamic.toml" >"${LINTO_SHARED_MOUNT}/traefik/dynamic.toml"

    # Check the deployment mode and choose the template accordingly
    if [[ "$1" == "LOCALHOST" ]]; then
        generate_certificate $2
        echo "Using a LOCALHOST configuration template."
        envsubst <"$CONFIG_TEMPLATES/traefik/traefik-mkcert.toml" >"$output_file"
    else
        echo "Using production configuration template."
        envsubst <"$CONFIG_TEMPLATES/traefik/traefik.toml" >"$output_file"
    fi
}

build_session() {
    echo "Building Live session..."
    create_networks "net_studio,session_network"

    mkdir -p ${LINTO_LOCAL_MOUNT}/database/postgres/db-session-database/
}

build_khaldi-french-streaming() {
    echo "Building Live streaming..."
    TARGET_FOLDER="${LINTO_SHARED_MOUNT}/models/AMs/french"

    if [ ! -d "$TARGET_FOLDER" ]; then
        ZIP_URL="https://dl.linto.ai/downloads/model-distribution/acoustic-models/fr-FR/linSTT_AM_fr-FR_v2.2.0.zip"
        ZIP_FILE="${TARGET_FOLDER}/linSTT_AM_fr-FR_v2.2.0.zip"

        echo "Creating target folder: $TARGET_FOLDER"
        mkdir -p "$TARGET_FOLDER"
        curl -L -o "$ZIP_FILE" "$ZIP_URL"
        unzip -o "$ZIP_FILE" -d "$TARGET_FOLDER"
        rm "$ZIP_FILE"
    fi

    TARGET_FOLDER="${LINTO_SHARED_MOUNT}/models/LMs/french"

    if [ ! -d "$TARGET_FOLDER" ]; then
        ZIP_URL="https://dl.linto.ai/downloads/model-distribution/decoding-graphs/LVCSR/fr-FR/decoding_graph_fr-FR_Big_v2.2.0.zip"
        ZIP_FILE="${TARGET_FOLDER}/linSTT_AM_fr-FR_v2.2.0.zip"
        echo "Creating target folder: $TARGET_FOLDER"
        mkdir -p "$TARGET_FOLDER"
        curl -L -o "$ZIP_FILE" "$ZIP_URL"
        unzip -o "$ZIP_FILE" -d "$TARGET_FOLDER"
        rm "$ZIP_FILE"
    fi
}

build_whisper-streaming() {
    echo "Building whisper..."

    mkdir -p ${LINTO_SHARED_MOUNT}/audios/api_uploads \
        ${LINTO_SHARED_MOUNT}/models/
}

build_kaldi-french-streaming() {
    echo "Building Live streaming..."
    TARGET_FOLDER="${LINTO_SHARED_MOUNT}/models/AMs/french"

    if [ ! -d "$TARGET_FOLDER" ]; then
        ZIP_URL="https://dl.linto.ai/downloads/model-distribution/acoustic-models/fr-FR/linSTT_AM_fr-FR_v2.2.0.zip"
        ZIP_FILE="${TARGET_FOLDER}/linSTT_AM_fr-FR_v2.2.0.zip"

        echo "Creating target folder: $TARGET_FOLDER"
        mkdir -p "$TARGET_FOLDER"
        curl -L -o "$ZIP_FILE" "$ZIP_URL"
        unzip -o "$ZIP_FILE" -d "$TARGET_FOLDER"
        rm "$ZIP_FILE"
    fi

    TARGET_FOLDER="${LINTO_SHARED_MOUNT}/models/LMs/french"

    if [ ! -d "$TARGET_FOLDER" ]; then
        ZIP_URL="https://dl.linto.ai/downloads/model-distribution/decoding-graphs/LVCSR/fr-FR/decoding_graph_fr-FR_Big_v2.2.0.zip"
        ZIP_FILE="${TARGET_FOLDER}/linSTT_AM_fr-FR_v2.2.0.zip"
        echo "Creating target folder: $TARGET_FOLDER"
        mkdir -p "$TARGET_FOLDER"
        curl -L -o "$ZIP_FILE" "$ZIP_URL"
        unzip -o "$ZIP_FILE" -d "$TARGET_FOLDER"
        rm "$ZIP_FILE"
    fi
}

build_whisper-streaming() {
    echo "Building whisper..."

    mkdir -p ${LINTO_SHARED_MOUNT}/audios/api_uploads \
        ${LINTO_SHARED_MOUNT}/models/
}

generate_certificate() {
    echo "Generating certificates..."
    domain=$1

    cert_file="$CERTS_DIR/${domain}.pem"
    cert_key_file="$CERTS_DIR/${domain}-key.pem"

    # Check if the certificates already exist
    if [[ -f "$cert_file" && -f "$cert_key_file" ]]; then
        echo "Certificates for $domain already exist in $CERTS_DIR"
    else
        echo "Generating certificates for $domain..."

        # Generate the certificate for the specified domains and move to the certs folder
        mkcert -cert-file "$cert_file" -key-file "$cert_key_file" "$domain"
        echo "Certificates generated successfully in $CERTS_DIR"
    fi
}

main() {
    case "$1" in
    stt)
        build_stt
        ;;
    llm)
        build_llm
        ;;
    studio)
        build_studio
        ;;
    traefik)
        build_traefik $2 $3
        ;;
    session-streaming)
        build_session
        ;;
    streaming-kaldi-french-streaming)
        build_kaldi-french-streaming
        ;;
    streaming-whisper-streaming)
        build_whisper-streaming
        ;;
    *)
        echo "Usage: $0 {stt|llm|studio|traefik}"
        exit 1
        ;;
    esac
}

main "$@"
