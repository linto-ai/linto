local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');

local gpu_mode = std.extVar('GPU_MODE');


local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/audios/api_uploads/:/opt/audio',
      ],
      networks: [
        'net_stt_services',
        'task_broker_services',
      ],
      environment: {
        SERVICES_BROKER: 'redis://task-broker-redis:6379',
        BROKER_PASS: '$REDIS_PASSWORD',
        QUEUE_NAME: 'diarization-pyannote',
        SERVICE_MODE: 'task',
        SERVICE_NAME: config.service_name,
        LANGUAGE: '*',
        DEVICE: gpu_mode,
        NVIDIA_VISIBLE_DEVICES: '0',
        NVIDIA_DRIVER_CAPABILITIES: 'all',
        MODEL_INFO: '{ "en": "Yes","fr":"Oui"}',
        CONCURRENCY: '1',
      },
    },
  },
  networks: {
    net_stt_services: {
      external: true,
    },
    task_broker_services: {
      external: true,
    }
  },
};

std.mergePatch(service, patch)
