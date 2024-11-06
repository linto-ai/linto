#!/bin/bash
set -uea
SUDO=''
if [ -f ".env" ]; then
    source .env
else
    source .envdefault
fi

# Get the current working directory
BASE_DIR=$(pwd)
JSONNET_DIR="${BASE_DIR}/jsonnet"

RUNNING_DIR="./running"

SERVICE_STT_GENERATED=false

# Function to generate service-YAML files
generate_yaml_files() {
    enable_session_studio=${ENABLE_SESSION_STUDIO:-false}

    local service_dir="$1"
    local expose_traefik="${2:-false}"
    local expose_gateway="${3:-false}"
    local gpu_mode="${4:-cpu}"
    local diarization_service="${5:-}"

    if [ -d "$service_dir" ] && [ -s "$service_dir/config.jsonnet" ] && [ -s "$service_dir/template.jsonnet" ]; then
        FILE_NAME=$(
            jsonnet \
                -V LINTO_IMAGE_TAG=$LINTO_IMAGE_TAG \
                -V LINTO_DOMAIN=$LINTO_DOMAIN \
                -V REDIS_PASSWORD=$REDIS_PASSWORD \
                -V DEPLOYMENT_MODE=$DEPLOYMENT_MODE \
                -V EXPOSE_TRAEFIK=$expose_traefik \
                -V EXPOSE_GATEWAY=$expose_gateway \
                "${service_dir}/config.jsonnet" | jq -r '.service_name'
        )

        echo -e "\e[32mBuilding $FILE_NAME.yml\e[0m"

        jsonnet -J ./jsonnet \
            -V LINTO_DOMAIN=$LINTO_DOMAIN \
            -V DEPLOYMENT_MODE=$DEPLOYMENT_MODE \
            -V DOCKER_NETWORK=$DOCKER_NETWORK \
            -V LINTO_LOCAL_MOUNT=$LINTO_LOCAL_MOUNT \
            -V LINTO_SHARED_MOUNT=$LINTO_SHARED_MOUNT \
            -V REDIS_PASSWORD=$REDIS_PASSWORD \
            -V LINTO_IMAGE_TAG=$LINTO_IMAGE_TAG \
            -V LINTO_FRONT_THEME=$LINTO_FRONT_THEME \
            -V EXPOSE_TRAEFIK=$expose_traefik \
            -V EXPOSE_GATEWAY=$expose_gateway \
            -V DIARIZATION_DEFAULT=$diarization_service \
            -V GPU_MODE=$gpu_mode \
            -V ENABLE_SESSION_STUDIO=$enable_session_studio \
            "${service_dir}/template.jsonnet" | yq eval -P - >"$RUNNING_DIR/$FILE_NAME.yaml"
    fi
}

build_main_service() {
    echo "Building traefik service..."
    generate_yaml_files "services/main/traefik"
    generate_yaml_files "services/main/api-gateway"
}

build_llm() {
    echo "Building LLM..."
    generate_yaml_files "services/llm/llm-gateway" $1 $2
    generate_yaml_files "services/stt/task-broker-redis"
    #generate_yaml_files "services/llm/vllm"
}

build_studio() {
    echo "Building Studio..."
    export ENABLE_SESSION_STUDIO="$1"
    if [ "$1" = "true" ]; then
        ENABLE_SESSION_STUDIO="WebServer,MongoMigration,BrokerClient,IoHandler"
    else
        ENABLE_SESSION_STUDIO="WebServer,MongoMigration"
    fi

    generate_yaml_files "services/studio/studio-api"

    export ENABLE_SESSION_STUDIO="$1"
    generate_yaml_files "services/studio/studio-frontend"
    generate_yaml_files "services/studio/studio-websocket"
}

build_stt_fr() {
    echo "Building STT FR..."
    generate_yaml_files "services/stt/french-whisper-v3" $1 $2 $3 $4

    if [ ! -f "$RUNNING_DIR/stt-mongo.yaml" ]; then
        generate_yaml_files "services/stt/stt-mongo"
        generate_yaml_files "services/stt/task-broker-redis"
    fi
}

build_stt_en() {
    echo "Building STT EN..."
    generate_yaml_files "services/stt/english-whisper-v3" $1 $2 $3 $4

    if [ ! -f "$RUNNING_DIR/stt-mongo.yaml" ]; then
        generate_yaml_files "services/stt/stt-mongo"
        generate_yaml_files "services/stt/task-broker-redis"
    fi
}

build_diarization() {
    echo "Building Diarization..."
    if [ "$2" = "true" ]; then
        generate_yaml_files "services/stt/diarization-pyannote-qdrant" false false $1
    else
        generate_yaml_files "services/stt/diarization-pyannote" false false $1
    fi
}

build_live_streaming() {
    echo "Building Live Streaming..."
    generate_yaml_files "services/live-session/session-api" $1 $2
    generate_yaml_files "services/live-session/session-broker"
    generate_yaml_files "services/live-session/session-postgres"
    generate_yaml_files "services/live-session/session-scheduler"
    generate_yaml_files "services/live-session/session-transcriber"
}

build_monitoring() {
    echo "Building Monitoring..."
    generate_yaml_files "services/monitoring/celery-flower-monitor" true
    generate_yaml_files "services/monitoring/swarmpit" true
}

# Parameters: $1 = service name,
# $2 = domain,$3 = deployment mode

# At that point parameter can change, but overall the $4 to $7 are the same
# $4 = Traefik exposed, $5 Gateway exposed
# $6 GPU enabled, $7 Diariation enabled

# Studio $4 is different,

main() {
    service=$1
    export LINTO_DOMAIN="$2" DEPLOYMENT_MODE="$3"

    traefik_exposed="${4:-false}"
    gateway_exposed="${5:-false}"
    gpu_enable="${6:-false}"
    diarization_enable="${7:-false}"
    speaker_identification="${8:-false}"

    case "$1" in
    stt-fr)
        build_stt_fr $traefik_exposed $gateway_exposed $gpu_enable $diarization_enable
        ;;
    stt-en)
        build_stt_en $traefik_exposed $gateway_exposed $gpu_enable $diarization_enable
        ;;
    diarization)
        build_diarization $gpu_enable $speaker_identification
        ;;
    llm)
        build_llm $traefik_exposed $gateway_exposed
        ;;
    studio)
        # Special rule for studio on param 4 who containing the information about live-streaming
        build_studio $4
        ;;
    live-streaming)
        build_live_streaming $traefik_exposed $gateway_exposed
        ;;
    monitoring)
        build_monitoring
        ;;
    main)
        build_main_service
        ;;
    *)
        echo "Usage: $0 {stt|llm|studio|traefik}"
        exit 1
        ;;
    esac
}

main "$@"
