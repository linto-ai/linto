local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/models/:/root/.cache',
        shared_mount + '/llm_services/:/usr/src/services/'
      ],
      networks: [
        'net_llm_services',
        '$DOCKER_NETWORK',
      ],
      environment: {
        PYTHONUNBUFFERED:1,
        SERVICE_NAME:'LLM_Gateway',
        OPENAI_API_BASE:'http://vllm-service:8000/v1',
        OPENAI_API_TOKEN:'EMPTY',
        HTTP_PORT:80,
        CONCURRENCY:1,
        TIMEOUT:60,
        SWAGGER_PREFIX:'',
        SWAGGER_PATH:'../document/swagger_llm_gateway.yml',
        RESULT_DB_PATH:'./results.sqlite',
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
