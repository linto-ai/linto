local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local domain = std.extVar('LINTO_DOMAIN');
local service = base.Service(config);
local network = std.extVar('DOCKER_NETWORK');
local local_mount = std.extVar("LINTO_LOCAL_MOUNT");


local patch = {
  services: {
    [config.service_name]: {
      networks: [
        'session_network',
        'net_studio'
      ],
      volumes: [
        local_mount+'/database/postgres/db-session-database:/data/db',
      ],
      environment: {
        POSTGRES_PASSWORD: 'mypass',
        POSTGRES_USER: 'myuser',
        POSTGRES_DB: 'session_DB',
      },
    },
    [config.service_name + '_migration']: {
      image: 'lintoai/studio-plugins-migration:latest',
      networks: [
        'session_network',
      ],
      deploy: {
        mode: 'replicated',
        replicas: 1, // constraints might be needed
        restart_policy: {
          condition: 'on-failure',
        }
      },
      environment: {
        DB_USER: 'myuser',
        DB_PASSWORD: 'mypass',
        DB_NAME: 'session_DB',
        DB_PORT: 5432,
        DB_HOST: config.service_name,  // task | http
        NODE_ENV: 'production',  // lin | vosk
      },
    },
  },
  networks: {
    session_network: {
      external: true,
    },
    net_studio: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)
