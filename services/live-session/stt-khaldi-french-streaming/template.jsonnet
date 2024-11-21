local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');
local network = std.extVar('DOCKER_NETWORK');


local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/audios/api_uploads/:/opt/audio',
        shared_mount + '/models/AMs/french:/opt/AM',
        shared_mount + '/models/LMs/french:/opt/LM',
      ],
      networks: [
        network,
        'session_network',
      ],
      environment: {
        SERVICE_MODE: 'websocket',  // task | http | websocket
        MODEL_TYPE: 'lin',  // lin | vosk
        ENABLE_STREAMING: 'true',
        STREAMING_PORT: '80',
        CONCURRENCY: '1',
        LANGUAGE: 'fr-FR',
      },
    },
  },
  networks: {
    session_network: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
