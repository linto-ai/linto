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
        network,
      ],
      environment: {
        SESSION_API_BASE_PATH:'/',
        STREAMING_HOST: 'session-transcriber',
        STREAMING_PROXY_HOST: domain,

        # check with JS these env configuration
        SESSION_API_WEBSERVER_HTTP_PORT:'80',
        STREAMING_WS_SECURE: true,
        
        STREAMING_PASSPHRASE:'false',
        STREAMING_USE_PROXY:'false',

        BROKER_HOST: 'session-broker',
        BROKER_PORT: 1883,
        BROKER_KEEPALIVE: 60,
        BROKER_PROTOCOL: 'mqtt',

        DB_HOST: 'session-postgres',
        DB_USER: 'myuser',
        DB_PASSWORD: 'mypass',
        DB_NAME: 'session_DB',
        DB_PORT: 5432,
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
