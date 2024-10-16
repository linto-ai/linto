local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local domain = std.extVar('LINTO_DOMAIN');
local service = base.Service(config);
local network = std.extVar('DOCKER_NETWORK');
local local_mount = std.extVar("LINTO_LOCAL_MOUNT");


local patch = {
  services: {
    [config.service_name]: {
      networks: [
        'net_stt_services',
      ],
      volumes: [
        local_mount+'/database/db-stt-services-data:/data/db',
      ],
    },
  },
  networks: {
    net_stt_services: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
