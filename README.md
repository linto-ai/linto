# LinTO Deployment Tool

## Overview

The LinTO Deployment Tool streamlines the setup, configuration, and deployment of LinTO Services, such as transcription and LinTO Studio. Leveraging Docker in Swarm mode, this tool efficiently manages complex deployments, including transcription services, diarization, and reverse proxy setups. It provides a simplified interface for deploying the entire LinTO suite on a single node, while also enabling scalability across multiple nodes if required.

For more details on LinTO Studio's Architecture, refer to [LINTO-STUDIO.md](LINTO-STUDIO.md).

## Features

- **Setup Script**: The `setup.sh` script initializes the environment, including configuring Docker in Swarm mode, setting up required networks, installing dependencies, and preparing services for deployment. It also generates a set of `.yaml` files in the `running` directory, which are later used by the `start.sh` script to launch the services. This process will not affect any Docker or Docker Compose services that are already running on your system.
- **Start Script**: The `start.sh` script deploys a stack of services using Docker Swarm, providing a straightforward approach to managing multiple services.
- **Environment Configuration**: The configuration is managed through a `.envdefault` file, which can be customized or overridden by creating a `.env` file to adjust deployment settings.

## Quick Start

### Prerequisites

- **Docker**: Ensure that Docker is installed. The `setup.sh` script will handle all Docker-related tasks, including initializing Swarm mode and setting up networks, so there is no need for manual configuration.
- **Optional**: Docker Desktop and WSL2 are required if you are working in a Windows environment.

### Setup

1. **Clone this repository** and navigate to the project directory.

2. **Configure the environment variables** by modifying `.envdefault` or creating a `.env` file to override the defaults. Environment variables are crucial for customizing your deployment. They define paths, network names, domain configurations, and other parameters used by the scripts during setup and deployment. By using a `.env` file, you can personalize your setup without modifying the default settings, which is useful for managing different environments.

3. **Run the setup script** to prepare the environment:

   ```bash
   ./setup.sh
   ```

   The `setup.sh` script is interactive and will guide you through several key steps, including:

   - **Cleanup Step**: The script removes `.yaml` files from the `running` directory, ensuring a fresh start.
   - **Dependencies Installation**: The script installs all necessary dependencies, including `dialog` for user interactions, `jsonnet` for generating configuration files, `apache2-utils` for authentication, `jq` for JSON processing, and `yq` for YAML processing. It also installs `mkcert` to create local SSL certificates.
   - **Service Configuration**: The script creates necessary networks and directories for various services. Depending on your selection, it sets up directories for STT (speech-to-text), LLM (large language model), LinTO Studio, and Traefik.
   - **Mode Selection**: You will be prompted to choose between 'server' and 'local' deployment modes. If you select 'server' mode, a Let's Encrypt certificate will be automatically generated for secure connections, whereas 'local' mode will generate certificates using `mkcert`.
   - **Service Selection**: The script allows you to select specific services to deploy, such as transcription (in different languages), diarization, summarization, live streaming, and LinTO Studio.
   - **GPU Configuration**: If your system has a GPU, you will be asked if you want to use GPU acceleration for the services.
   - **Deployment Configuration**: The script configures Docker Swarm, setting up the Swarm mode if it is not already active. It may also promote worker nodes to manager nodes if necessary.
   - **Building Services**: The script generates `.yaml` configuration files for the selected services using predefined templates, ensuring that all necessary services are properly built and configured for deployment.

### Start Services

To launch the LinTO services, run:

```bash
./start.sh
```

This script will deploy all services defined in the `./running` directory as a Docker stack, utilizing Docker Swarm to orchestrate the deployment.

### Example `.env` Configuration

To customize your deployment, copy `.envdefault` to `.env` and modify the variables as needed. Below is an example based on typical settings in `.envdefault`:

[See Detailed Environment Settings](#detailed-environment-settings)

```ini
# Docker network to be used for the deployment
DOCKER_NETWORK=linto
# The name of the Docker stack used for deployment
LINTO_STACK_NAME=linto

# HTTP authentication for accessing some services
LINTO_HTTP_USER=linto
LINTO_HTTP_PASSWORD=LINAGORA

# Docker image tag for LinTO services (e.g., latest, latest-unstable)
LINTO_IMAGE_TAG=latest-unstable

# Directory to be used for storing shared and local data (audio uploads, configuration files, etc.)
LINTO_SHARED_MOUNT=~/shared_mount
LINTO_LOCAL_MOUNT=~/deployment_config

# Redis configuration (password for Redis services)
REDIS_PASSWORD=My_Password

# Theme settings for the LinTO front-end interface
LINTO_FRONT_THEME=LinTO-green

# Default permissions for new organizations (upload, summary, session)
ORGANIZATION_DEFAULT_PERMISSIONS=upload,summary,session

# Superuser settings
SUPER_ADMIN_EMAIL=superadmin@mail.com
SUPER_ADMIN_PWD=superadmin
```

The .env file allows you to configure Docker networks, authentication, stack names, paths for shared and local mounts, Redis settings, and the visual theme of the front-end. Be sure to adjust these variables according to your deployment needs.

## Use Cases

The deployment tool can be used for:

- **Deploying LinTO Studio**: LinTO Studio is a media management platform that provides a powerful web interface for managing transcription sessions and interacting with LinTO services. It offers features such as real-time transcription, closed-captioning, and diarization, allowing users to effectively manage and analyze multimedia content. For more information, visit the [LinTO Studio GitHub page](https://github.com/linto-ai/linto-studio).
- **Deploying transcription services**: This tool utilizes Whisper models for high-accuracy, GPU-accelerated processing of audio data. These models are designed to deliver cutting-edge performance in transcription accuracy, particularly for scenarios requiring detailed linguistic analysis, and they can leverage GPU capabilities to handle resource-intensive tasks efficiently.
- **Setting up advanced diarization and transcription services**: The tool includes features to accurately identify speakers and generate precise transcriptions.
- **Configuring an API gateway**: The deployment includes an API gateway for seamless integration with LinTO Studio or other external services.

## Infrastructure Requirements

The infrastructure requirements vary based on the services you intend to deploy. Here are some general guidelines:

- **CPU Deployment**: Suitable for development or low-demand scenarios, such as testing or small-scale deployments, which can be run on a typical local machine or a small cloud instance.
- **GPU Deployment**: Recommended for Whisper models or real-time transcription, as these services are computationally intensive. For production-level deployment involving real-time transcriptions, a machine with a compatible Nvidia GPU is highly advised.

### Configuring GPU with Nvidia Container Runtime, CUDA, and DKMS

To ensure proper GPU utilization when using Docker Swarm, you need to configure the Nvidia container runtime, CUDA, and Nvidia drivers. Since Docker Swarm does not support the `--gpus` flag like a simple Docker runtime, you must configure `/etc/docker/daemon.json` as follows to enable GPU capabilities:

```bash
# Configure Docker to use the NVIDIA Container Runtime
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "default-runtime": "nvidia"
}
EOF
```

### Additional Requirements

- **Nvidia Container Toolkit**: Install the Nvidia Container Toolkit to provide Docker containers with GPU support. Follow Nvidia's official documentation for installation instructions.
- **CUDA**: CUDA is required for GPU acceleration. Install the appropriate version that matches your GPU and the software requirements. Refer to Nvidia's compatibility guide for choosing the correct version.
- **Nvidia Drivers**: Make sure you have the correct Nvidia drivers installed. These drivers must be compatible with CUDA and the Nvidia container runtime.

### Specific Considerations for WSL2 and Docker Desktop Users

If you are using WSL2 with Docker Desktop, GPU access must be explicitly enabled, and Docker runtime settings may need adjustments to support GPU-based workloads. Ensure that Docker Desktop is configured to use WSL2 and that GPU sharing is enabled for GPU-intensive services.

You will need to configure the Docker Engine to enable GPU capabilities by adding the following configuration in Docker Desktop's settings under "Docker Engine":

```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}
```

This configuration enables Docker to use the Nvidia runtime for GPU-accelerated tasks, ensuring compatibility with GPU-based services.

## How the Scripts Work

### `setup.sh`

The `setup.sh` script handles several key tasks, including:

- **Cleaning up old configurations**: Removes outdated or conflicting setup files to ensure a clean start.
- **Running dependencies setup**: Installs all necessary services and tools required by the LinTO suite.

This script prepares everything required for a seamless deployment, from clearing temporary files to setting up the `running` directory and configuring Docker.

### `start.sh`

The `start.sh` script deploys the services using Docker Swarm by reading the configuration files located in the `./running` directory. Each service is deployed as part of a stack, ensuring that all services are well-integrated. You do not need to handle the underlying Docker commands `start.sh` simplifies this process for you.

## Browser Configuration for HTTPS (Self-Signed Certificates)

If running locally or using self-signed certificates, browsers may require manual configuration to accept these certificates. You might encounter warnings when accessing the LinTO services via HTTPS. This is expected for self-signed certificates, and you can manually approve the certificate in your browser settings to proceed.

## Using curl with Self-Signed Certificates

When interacting with LinTO services via the command line using curl, self-signed certificates may cause security warnings or connection errors. To bypass these errors for local testing, you can use the -k or --insecure option, which tells curl to ignore certificate validation.

Example:

```bash
curl -k https://yourdomain.com/api
```

This will allow curl to proceed without verifying the self-signed certificate. However, for production environments.

## Scaling Notes

The provided scripts focus on deploying LinTO on a single-node Docker Swarm; however, you can scale the deployment across multiple nodes by adjusting the Docker Swarm configuration. For larger deployments, adding nodes to your Docker Swarm will help with load distribution and enhance reliability.

## Access to Endpoints

This documentation outlines the different access points for interacting with services through web interfaces, Swagger, and APIs registered behind the gateway. The URLs below use `localhost` as the default value, but they can be adjusted based on the domain used during deployment.

> **Note**: Replace `localhost` with the appropriate domain during deployment to match your configuration.

### Web Interface

The following interfaces can be accessed via a web browser to monitor and manage the system:

- **Studio Front**: Available at [https://localhost/](https://localhost/), this interface allows interaction with the studio front-end.
- **Swarmpit**: Available at [https://localhost/monitoring-swarmpit/](https://localhost/monitoring-swarmpit/), this interface allows monitoring of Docker Swarm containers and services.
- **Celery**: Available at [https://localhost/monitoring-celery/](https://localhost/monitoring-celery/), this interface monitors the background tasks run by Celery.

### API Documentation via Swagger

The following APIs expose their documentation via Swagger, enabling easier exploration and testing of there api:

- **Studio API**: [https://localhost/cm-api/apidoc/#/](https://localhost/cm-api/apidoc/#/), documentation for the studio API that manages backend services.
- **Session API**: [https://localhost/session-api/api-docs/#/](https://localhost/session-api/api-docs/#/), documentation for the API handling user of live sessions.
- **STT French Whisper v3**: [https://localhost/stt-french-whisper-v3/docs/#/](https://localhost/stt-french-whisper-v3/docs/#/), documentation for the Speech-to-Text API in French (based on Whisper v3).
- **STT English Whisper v3**: [https://localhost/stt-english-whisper-v3/docs/#/](https://localhost/stt-english-whisper-v3/docs/#/), documentation for the Speech-to-Text API in English (based on Whisper v3).
- **LLM Gateway**: [https://localhost/llm-gateway/docs/#/](https://localhost/llm-gateway/docs/#/), documentation for the Large Language Model (LLM) Gateway API.

### Exposed API via Traefik

The following APIs are exposed and routed through the Traefik reverse proxy, allowing direct interaction with backend services if enable:

- **Studio API**: [https://localhost/cm-api/](https://localhost/cm-api/)
- **Session API**: [https://localhost/session-api/](https://localhost/session-api/)
- **STT French Whisper v3**: [https://localhost/stt-french-whisper-v3/](https://localhost/stt-french-whisper-v3/)
- **STT English Whisper v3**: [https://localhost/stt-english-whisper-v3/](https://localhost/stt-english-whisper-v3/)
- **LLM Gateway**: [https://localhost/llm-gateway/](https://localhost/llm-gateway/)

### Exposed API via Gateway

The APIs are also accessible behind the Gateway, centralizing access to the services if enable:

- **Studio API**: [https://localhost/gateway/cm-api/](https://localhost/gateway/cm-api/)
- **Session API**: [https://localhost/gateway/session-api/](https://localhost/gateway/session-api/)
- **STT French Whisper v3**: [https://localhost/gateway/stt-french-whisper-v3/](https://localhost/gateway/stt-french-whisper-v3/)
- **STT English Whisper v3**: [https://localhost/gateway/stt-english-whisper-v3/](https://localhost/gateway/stt-english-whisper-v3/)
- **LLM Gateway**: [https://localhost/gateway/llm-gateway/](https://localhost/gateway/llm-gateway/)

## Detailed Environment Settings

### Creating a Superuser for Back Office Access

The superuser has an administrative access to the back office of studio, which includes managing organization creation, assigning default permissions, and overseeing users within organizations. To set up a superuser, configure the following environment variables in your `.env` file:

```bash
SUPER_ADMIN_EMAIL=superadmin@mail.fr
SUPER_ADMIN_PWD=superadminpassword
```

The superuser will have the authority to define organization-wide settings, manage user roles and can monitore all live sessions.

### Default Permissions for User-Created Organizations

By default, each newly created organization is granted the following permissions, which define what members can do within the organization:

- **Upload**: Grants access to use the transcription service to upload and process media.
- **Summary**: Enables the use of large language models (LLM) to generate summaries for uploaded media.
- **Session**: Provides access to the Session API, allowing the organization to create live meetings.

These default permissions can be set up on project startup or adjusted individually in the back office by the superuser.
To configure default permissions at startup, set the following variable in the `.env` file:

```bash
ORGANIZATION_DEFAULT_PERMISSIONS=upload,summary,session
```

> **Note**: If any default permission is removed, future organizations will not have access to that functionality unless the superuser grants it in the back office.
> **Note**: To disable all permissions, set `ORGANIZATION_DEFAULT_PERMISSIONS=none`

### Member Roles in an Organization

An organization can be structured with various user roles, each granting specific permissions. The default role is **Member**, and each subsequent role inherits the permissions of the previous one, as outlined below:

- **Member**: Can view and edit any media regarding of the media permission.
- **Uploader**: Can create and upload new media.
- **Meeting Manager**: Has the ability to initiate and manage sessions.
- **Maintainer**: Manages all users within the organization.
- **Admin**: Has full control over all organization actions and settings, including permissions and user management.

These roles allow for a structured, role-based permission system within each organization, ensuring that each user has the appropriate level of access based on their responsibilities.
