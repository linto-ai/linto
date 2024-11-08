local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local shared_mount = std.extVar('LINTO_SHARED_MOUNT');
local redis_password = std.extVar('REDIS_PASSWORD');

local gpu_mode = std.extVar('GPU_MODE');


local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + '/audios/api_uploads/:/opt/audio',
        shared_mount + '/audios/speaker_samples:/opt/speaker_samples', # Reference speakers samples
      ],
      networks: [
        'net_stt_services',
        'task_broker_services',
      ],
      environment: {
        SERVICES_BROKER: 'redis://task-broker-redis:6379',
        BROKER_PASS: redis_password,
        QUEUE_NAME: 'diarization-pyannote',
        SERVICE_MODE: 'task',
        SERVICE_NAME: config.service_name,
        LANGUAGE: '*',
        DEVICE: gpu_mode,
        NVIDIA_VISIBLE_DEVICES: '0',
        NVIDIA_DRIVER_CAPABILITIES: 'all',
        MODEL_INFO: '{ "en": "Yes","fr":"Oui"}',
        CONCURRENCY: '1',
        QDRANT_HOST: 'qdrant-vector-db',
        QDRANT_PORT: '6333',
        QDRANT_COLLECTION_NAME: 'speaker_embeddings',
        QDRANT_RECREATE_COLLECTION: 'true'
      },
    },
    'qdrant-vector-db' : {
      image: 'qdrant/qdrant',
      volumes: [
        shared_mount + '/qdrant_storage:/qdrant/storage:z',
      ],
      networks: [
        'net_stt_services'
      ],
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
