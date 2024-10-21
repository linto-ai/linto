local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');
local network = std.extVar('DOCKER_NETWORK');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/models/:/root/.cache/huggingface',
      ],
      networks: [
        'net_llm_services',
        network,
      ],
      environment: {
        NVIDIA_VISIBLE_DEVICES: '0',
        NVIDIA_DRIVER_CAPABILITIES: 'all',
      },
    },
  },
  networks: {
    net_llm_services: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
