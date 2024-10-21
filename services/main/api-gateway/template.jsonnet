local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local network = std.extVar('DOCKER_NETWORK');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        '/var/run/docker.sock:/var/run/docker.sock:ro',
      ],
      networks: [
        'net_stt_services',
        network,
      ],
      environment: {
        COMPONENT: 'ServiceWatcher,WebServer',
      },
    },
  },
  networks: {
    net_stt_services: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
