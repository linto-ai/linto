local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');

local patch = {
  services: {
    [config.service_name]: {
      networks: [
        'session_network',
        'net_studio'
      ],
      expose: [
        "1883"
      ],
      ports: [
        "1883:1883"
      ],
    },
  },
  networks: {
    session_network: {
      external: true,
    },
    net_studio: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
