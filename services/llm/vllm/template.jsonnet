local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/models/:/root/.cache/huggingface',
      ],
      networks: [
        'net_llm_services',
        '$DOCKER_NETWORK',
      ],
    },
  },
  networks: {
    net_llm_services: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
