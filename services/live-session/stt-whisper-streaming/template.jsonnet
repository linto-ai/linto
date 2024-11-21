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
        shared_mount + '/models/:/root/.cache'
      ],
      networks: [
        network,
        'session_network',
      ],
      environment: {
        SERVICE_MODE: 'websocket',  // task | http | websocket
        MODEL_TYPE: 'whisper',      // lin | vosk
        MODEL: 'base',              // tiny | base | simple | medium || large-v3
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
