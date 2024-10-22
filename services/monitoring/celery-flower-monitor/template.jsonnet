local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local network = std.extVar('DOCKER_NETWORK');
local redis_password = std.extVar('REDIS_PASSWORD');

local patch = {
  services: {
    [config.service_name]: {
      networks: [
        'task_broker_services',
        network,
      ],
      environment: {
        SERVING_PORT: 80, 
        SERVICE_PORT: 80,
        SERVICES_BROKER: 'redis://task-broker-redis:6379',
        BROKER_PASS: redis_password,
        LINTO_STACK_TASK_MONITOR_SERVING_URL: 'monitoring-celery',
      },
    },
  },
  networks: {
    task_broker_services: {
      external: true,
    }
  },
};

std.mergePatch(service, patch)
