local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');
local network = std.extVar('DOCKER_NETWORK');
local redis_password = std.extVar('REDIS_PASSWORD');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/models/:/root/.cache',
        shared_mount + '/llm_services/:/usr/src/services/'
      ],
      networks: [
        'net_llm_services',
        'task_broker_services',
        network,
      ],
      environment: {
        PYTHONUNBUFFERED:1,
        SERVICE_NAME:'LLM_Gateway',
        OPENAI_API_BASE: 'https://chat.ai.linagora.exaion.com/v1/',
        OPENAI_API_TOKEN:'EMPTY',
        HTTP_PORT:80,
        CONCURRENCY:1,
        TIMEOUT:60,
        SWAGGER_PREFIX:'/llm-gateway',
        SWAGGER_URL: '/llm-gateway',
        SWAGGER_PATH:'../document/swagger_llm_gateway.yml',
        RESULT_DB_PATH:'./results.sqlite',
        SERVICES_BROKER: 'redis://task-broker-redis:6379',
        BROKER_PASS: redis_password,
      },
    },
  },
  networks: {
    net_llm_services: {
      external: true,
    },
    task_broker_services: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
