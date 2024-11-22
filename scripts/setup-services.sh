#!/bin/bash
set -uea
SUDO=''
if [ -f ".env" ]; then
    source .env
else
    source .envdefault
fi
CONFIG_TEMPLATES="./conf-templates"

init_swarm_and_update_node() {
    if ! docker info | grep -q "Swarm: active"; then
        echo "Initializing Docker Swarm..."
        docker swarm init

        nodeId=$(docker node ls --filter role=manager --format '{{.ID}}' | head -n 1)
        docker node update --role manager --label-add ip=ingress "$nodeId"
    else
        echo "Docker Swarm is already initialized."

        # Check if there are any existing manager nodes
        existing_managers=$(docker node ls --filter role=manager --format '{{.ID}}' | while read -r node_id; do
            if docker node inspect "$node_id" | grep -q '"ip": "ingress"'; then
                break
            fi
        done)

        if [ -n "$existing_managers" ]; then
            echo "A manager node already exists. No update needed."
            return
        fi

        nodeId=$(docker node ls --filter role=manager --format '{{.ID}}' | head -n 1)
        if [ -n "$nodeId" ]; then
            docker node update --role manager --label-add ip=ingress "$nodeId"
        else
            echo "No worker node found to promote."
        fi
    fi

}

build_stt_fr() {
    echo "Building STT FR..."
    # Add your build commands for STT FR here
}

build_stt_en() {
    echo "Building STT EN..."
    # Add your build commands for STT EN here
}

build_diarization() {
    echo "Building Diarization..."
    # Add your build commands for Diarization here
}

build_live_streaming() {
    echo "Building Live Streaming..."
    # Add your build commands for Live session here
}

build_api_gateway() { # Function to build API Gateway
    echo "Building API Gateway..."
    # Add your build commands for API Gateway here
}

trigger_build_service() {
    services=$(./scripts/dialog.sh "services")
    expose_results=$(./scripts/dialog.sh "expose")
    read expose_traefik expose_api_gateway <<<"$expose_results"

    # Final output

    echo "Selected deployment mode: $LINTO_DOMAIN"
    echo "Selected services: $services ##"
    echo "Expose Directly: $expose_traefik"
    echo "Expose with API Gateway: $expose_api_gateway"

    # Always build Traefik
    build_api_gateway

    #TODO: we expose to the gateway when studio is selected
    gpu_enable=false
    vllm_enable=false
    diarization_enable=""
    live_streaming_enable=false
    speaker_identification="false"
    if [[ "$services" =~ (^|[[:space:]])3($|[[:space:]]) && "$services" =~ (^|[[:space:]])(1|2)($|[[:space:]]) ]]; then
        speaker_identification=$(./scripts/dialog.sh "speaker_identification")

        if [[ "$speaker_identification" == "true" ]]; then
            diarization_enable="stt-diarization-pyannote-qdrant"
        else
            diarization_enable="stt-diarization-pyannote"
        fi
    fi    
    if [[ "$services" =~ (^|[[:space:]])6($|[[:space:]]) ]]; then
        echo "Studio is selected, forcing API Gateway"
        expose_api_gateway=true
    fi
    if [[ "$services" =~ (^|[[:space:]])5($|[[:space:]]) ]]; then
        echo "Studio is selected, forcing API Gateway"
        live_streaming_enable=true
    fi
    if [[ "$services" =~ (^|[[:space:]])4($|[[:space:]]) ]]; then
        vllm_enable=$(./scripts/dialog.sh "vllm")
    fi

    ./scripts/build-services.sh "main" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE"

    # Iterate over each choice entered
    for service in $services; do
        case "$service" in
        1 | 2 | 3)
            ./scripts/build-config.sh "stt"

            if [ "$gpu_enable" = false ]; then
                gpu_enable=$(./scripts/dialog.sh "gpu")
            fi

            case "$service" in
            1)
                build_stt_fr
                ./scripts/build-services.sh "stt-fr" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" "$expose_traefik" "$expose_api_gateway" "$gpu_enable" "$diarization_enable"
                ;;
            2)
                build_stt_en
                ./scripts/build-services.sh "stt-en" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" "$expose_traefik" "$expose_api_gateway" "$gpu_enable" "$diarization_enable"
                ;;
            3)
                # No need of building diarization service if there is no stt service
                if [[ "$services" =~ (^|[[:space:]])(1|2)($|[[:space:]]) ]]; then
                    build_diarization
                    ./scripts/build-services.sh "diarization" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" "$expose_traefik" "$expose_api_gateway" "$gpu_enable" "$diarization_enable" "$speaker_identification"
                fi
                ;;
            esac
            ;;

        4)
            ./scripts/build-config.sh "llm"
            ./scripts/build-services.sh "llm" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" "$expose_traefik" "$expose_api_gateway" "" "" "" "$vllm_enable"
            ;;
        5)

            ./scripts/build-config.sh "session-streaming"
            ./scripts/build-services.sh "session-streaming" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" "$expose_traefik" "$expose_api_gateway"

            streaming_service_select=$(./scripts/dialog.sh "streaming_service")
            if [[ "$streaming_service_select" =~ (^|[[:space:]])(1)($|[[:space:]]) ]]; then
                echo "Building Kaldi French Streaming..."
                ./scripts/build-config.sh "streaming-kaldi-french-streaming"
                ./scripts/build-services.sh "streaming-kaldi-french-streaming" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" "$expose_traefik" "$expose_api_gateway"
            fi

            if [[ "$streaming_service_select" =~ (^|[[:space:]])(2)($|[[:space:]]) ]]; then
                echo "Building whisper Streaming..."
                if [ "$gpu_enable" = false ]; then
                    gpu_enable=$(./scripts/dialog.sh "gpu")
                fi

                ./scripts/build-config.sh "streaming-whisper-streaming"
                ./scripts/build-services.sh "streaming-whisper-streaming" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" "$expose_traefik" "$expose_api_gateway" "$gpu_enable"
            fi

            ;;
        6)
            ./scripts/build-config.sh "studio"
            ./scripts/build-services.sh "studio" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE" $live_streaming_enable #By default it's exposed to Traefik
            ;;
        7)
            ./scripts/build-services.sh "monitoring" "$LINTO_DOMAIN" "$DEPLOYMENT_MODE"
            ;;
        *)
            echo "Invalid option: $service"
            ;;
        esac
    done
}

select_deployment_mode() {
    selected_mode=$(./scripts/dialog.sh "deployment")

    # Process the selected mode
    case "$selected_mode" in
    1)
        export DEPLOYMENT_MODE="ONLINE_MACHINE"
        ;;
    2)
        export DEPLOYMENT_MODE="LOCALHOST"
        ;;
    *)
        echo "No valid option selected."
        exit 1
        ;;
    esac

    domain=$(./scripts/dialog.sh "domain")
    echo "Selected domain: $domain"
    LINTO_DOMAIN=$domain
    export LINTO_DOMAIN

    # Call your script to configure traefik with the deployment mode
    ./scripts/build-config.sh "traefik" "$DEPLOYMENT_MODE" "$domain"
}

init_swarm_and_update_node
select_deployment_mode
trigger_build_service
