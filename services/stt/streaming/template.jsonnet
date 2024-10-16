local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');

local patch = {
  services: {
    [config.service_name]: {
      image: 'lintoai/linto-platform-stt:latest-unstable',
      volumes: [
        shared_mount + '/audios/api_uploads/:/opt/audio',
        shared_mount + '/models/AMs/french_am_best:/opt/AM',
        shared_mount + '/models/LMs/french_big:/opt/LM',
      ],
      networks: [
        'linto-saas',
      ],
      environment: {
        SERVICE_MODE: 'http',  // task | http | websocket
        MODEL_TYPE: 'lin',  // lin | vosk
        ENABLE_STREAMING: 'true',
        STREAMING_PORT: '80',
        CONCURRENCY: '1',
        LANGUAGE: 'fr-FR',
      },
    },
  }
};

std.mergePatch(service, patch)
