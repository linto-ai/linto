local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);

local patch = {
  services: {
    [config.service_name]: {
      networks: [
        'task_broker_services',
        '$DOCKER_NETWORK',
      ],
      environment: {
        SERVING_PORT: 80, 
        SERVICE_PORT: 80,
        SERVICES_BROKER: 'redis://task-broker-redis:6379',
        BROKER_PASS: '$REDIS_PASSWORD',
        LINTO_STACK_TASK_MONITOR_SERVING_URL: 'celery',
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
