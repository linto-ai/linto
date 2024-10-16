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
      environment: {
        DB_HOST: 'session-postgres',
        DB_USER: 'myuser',
        DB_PASSWORD: 'mypass',
        DB_NAME: 'session_DB',
        DB_PORT: 5432,

        BROKER_HOST: 'session-broker',
        BROKER_PORT: 1883,
        BROKER_KEEPALIVE: 60,
        BROKER_PROTOCOL: 'mqtt',

        SCHEDULER_WEBSERVER_HTTP_PORT: 80,
        DEBUG: 'scheduler',
      }
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
