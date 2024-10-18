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

3. **IRun the setup script** to prepare the environment:

   ```bash
   ./setup.sh
   ```

   The `setup.sh` script is interactive and will guide you through several key steps, including:

   - **Cleanup Step**: The script removes old symbolic links, outdated `.dockerenv` files, and `.yaml` files from the `running` directory, ensuring a fresh start.
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

```ini
# Directory to be used for storing data used between services (audio uploads, configuration files...)
LINTO_SHARED_MOUNT=/path/to/shared/mount

# The name of the Docker stack used for deployment
LINTO_STACK_NAME=linto-stack

# Domain settings (example for local testing, can be yourdmain.com)
LINTO_DOMAIN=localhost

# Enable GPU support (set to true if GPU is available)
ENABLE_GPU=true

# Path to SSL certificates for secure connections
CERTS_DIR=/path/to/certs
```

The `.env` file allows you to specify paths, stack names, domain settings, GPU usage, and other parameters that help optimize and personalize your deployment. If you choose 'server' mode instead of 'local' mode when launching the script, a Let's Encrypt certificate will be automatically generated for secure connections.

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

The `start.sh` script deploys the services using Docker Swarm by reading the configuration files located in the `./running` directory. Each service is deployed as part of a stack, ensuring that all services are well-integrated. You do not need to handle the underlying Docker commands—`start.sh` simplifies this process for you.

## Browser Configuration for HTTPS (Self-Signed Certificates)

If running locally or using self-signed certificates, browsers may require manual configuration to accept these certificates. You might encounter warnings when accessing the LinTO services via HTTPS. This is expected for self-signed certificates, and you can manually approve the certificate in your browser settings to proceed.

## Scaling Notes

The provided scripts focus on deploying LinTO on a single-node Docker Swarm; however, you can scale the deployment across multiple nodes by adjusting the Docker Swarm configuration. For larger deployments, adding nodes to your Docker Swarm will help with load distribution and enhance reliability.
