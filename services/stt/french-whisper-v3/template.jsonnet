local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');
local tag = std.extVar('LINTO_IMAGE_TAG');
local network = std.extVar('DOCKER_NETWORK');
local redis_password = std.extVar('REDIS_PASSWORD');

local gpu_mode = std.extVar('GPU_MODE');
local diarization_default = std.extVar('DIARIZATION_DEFAULT');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/audios/api_uploads/:/opt/audio',
      ],
      networks: [
        'net_stt_services',
        'task_broker_services',
        network,
      ],
      environment: {
        SERVICE_NAME: config.service_name,
        LANGUAGE: 'fr-FR',
        RESSOURCE_FOLDER: shared_mount,
        KEEP_AUDIO: 0,
        CONCURRENCY: '1',
        SERVICES_BROKER: 'redis://task-broker-redis:6379',
        BROKER_PASS: redis_password,
        MODEL_TYPE: 'whisper',  // lin | vosk
        MONGO_HOST: 'stt-mongo', 
        MONGO_PORT: 27017,
        RESOLVE_POLICY: 'ANY',
        DIARIZATION_DEFAULT: diarization_default,
        MODEL_QUALITY: 1,
        ACCOUSTIC: 1
      },
    },
    [config.service_name + '_workers']: {
      image: 'lintoai/linto-stt-whisper:'+tag,
      command:[
      ],
      volumes: [
        shared_mount + '/audios/api_uploads/:/opt/audio',
        shared_mount + '/models/:/root/.cache'
      ],
      networks: [
        'net_stt_services',
        'task_broker_services',
      ],
      deploy: {
        mode: 'replicated',
        replicas: 1, // constraints might be needed
        restart_policy: {
          condition: 'on-failure',
        }
      },
      environment: {
        SERVICE_MODE: 'task',  // task | http
        MODEL_TYPE: 'whisper',  // lin | vosk
        SERVICE_NAME: config.service_name,
        SERVICES_BROKER: 'redis://task-broker-redis:6379',
        BROKER_PASS: redis_password,
        LANGUAGE: 'fr-FR',
        MODEL: 'large-v3',
        DEVICE: gpu_mode,
        NVIDIA_VISIBLE_DEVICES: '0',
        NVIDIA_DRIVER_CAPABILITIES: 'all',
        CONCURRENCY: '1'
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
