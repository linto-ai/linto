local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        '/var/run/docker.sock:/var/run/docker.sock:ro',
      ],
      networks: [
        'net_stt_services',
        '$DOCKER_NETWORK',
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
