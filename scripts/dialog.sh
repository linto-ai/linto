#!/bin/bash

DIALOG_HEIGHT=20
DIALOG_WIDTH=100

DIARIZATION_OPTIONS=("diarization-pyanote" "diarization-pybk" "disable")
STT_MODEL_OPTION=("whisper-fr" "whisper-en-v3-large" "whisper-fr-v2-medium" "linto-fr")
LLM_MODEL_OPTIONS=("casperhansen/llama-3-8b-instruct-awq" "other-model-1" "other-model-2")

# Function to display the dialog for exposing options
dialog_expose_show() {
    dialog --title "Access to any service" --checklist \
        "How to access any selected service (use space to select):" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2 \
        1 "Expose the services directly to the domain" off \
        2 "Expose with your custom API Gateway (will be forced if LinTO studio is selected)" off \
        3>&1 1>&2 2>&3 | tr '\n' ' ' | sed 's/ *$//'
}

dialog_expose() {
    expose_results=$(dialog_expose_show)

    local expose_directly="false"
    local expose_api_gateway="false"

    for option in $expose_results; do
        case $option in
        1)
            expose_directly="true"
            ;;
        2)
            expose_api_gateway="true"
            ;;
        esac
    done

    echo "$expose_directly $expose_api_gateway"
}

dialog_services_show() {
    dialog --checklist "Select any services to deploy:" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 6 \
        1 "French Transcription service fr" off \
        2 "English Transcription service" off \
        3 "Enable diarization service" off \
        4 "Summarization service" off \
        5 "Live streaming service" off \
        6 "LinTO Studio" off \
        7 "Monitoring tools" off \
        3>&1 1>&2 2>&3 | tr '\n' ' ' | sed 's/ *$//'
}

dialog_services() {
    selected_services=$(dialog_services_show)
    # Initialize speaker identification variable
    local speaker_identification="false"

    # Check if diarization is selected
    if [[ "$selected_services" == *"3"* ]]; then
        speaker_identification_choice=$(dialog --title "Speaker Identification" --radiolist \
            "Enable Speaker Identification?" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2 \
            1 "Enable" off \
            2 "Disable" off \
            3>&1 1>&2 2>&3)

        case "$speaker_identification_choice" in
        1)
            speaker_identification="true"
            ;;
        2)
            speaker_identification="false"
            ;;
        esac
    fi
    echo "$speaker_identification $selected_services"
}

dialog_deployment_mode() {
    selected_mode=$(dialog --title "Select Deployment Mode" --radiolist \
        "Choose a deployment mode:" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2 \
        1 "On an online machine with host" off \
        2 "On my local machine" off \
        3>&1 1>&2 2>&3)

    echo "$selected_mode"
}

dialog_domain() {
    default_domain="localhost"
    warning_message="Note: If you use 'localhost', your browser may not allow unsecure certificates."

    # Ask for the domain to expose the stack, default is localhost
    domain=$(dialog --title "Domain Configuration" --inputbox \
        "$warning_message\n\nPlease enter the domain you want to expose your stack (default: localhost):" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$default_domain" \
        3>&1 1>&2 2>&3)

    domain=${domain:-$default_domain}
    echo "$domain"
}

dialog_gpu_mode() {
    has_gpu=$(dialog --title "GPU Availability" --radiolist \
        "Does your computer have a GPU?" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2 \
        1 "Yes, my computer has a GPU" off \
        2 "No, my computer does not have a GPU" off \
        3>&1 1>&2 2>&3)

    if [ "$has_gpu" -eq 1 ]; then
        echo "cuda"
    else
        echo "cpu"
    fi
}

main() {
    case "$1" in
    expose)
        dialog_expose
        ;;
    services)
        dialog_services
        ;;
    deployment)
        dialog_deployment_mode
        ;;
    gpu)
        dialog_gpu_mode
        ;;
    domain)
        dialog_domain
        ;;
    *)
        echo "Usage: $0 {expose|transcription|deployment|gpu}"
        exit 1
        ;;
    esac
}

main $1
