local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/redis/redis.conf:/usr/local/etc/redis/redis.conf',
      ],
      networks: [
        'task_broker_services',
      ],
    },
  },
  networks: {
    task_broker_services: {
      external: true,
    }
  },
};

std.mergePatch(service, patch)
