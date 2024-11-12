local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local network = std.extVar('DOCKER_NETWORK');
local shared_mount = std.extVar("LINTO_SHARED_MOUNT");
local local_mount = std.extVar("LINTO_LOCAL_MOUNT");
local domain = std.extVar("LINTO_DOMAIN");

local enable_session_studio = std.extVar('ENABLE_SESSION_STUDIO');

local patch = {
  services: {
    [config.service_name]: {
      volumes: [
        shared_mount + "/conversation-manager/:/usr/src/app/conversation-manager/storages/"
      ],
      environment: {
        COMPONENTS: std.toString(enable_session_studio),
        DB_MIGRATION_TARGET:'1.5.2',
        DB_REQUIRE_LOGIN: 'false',
        DB_HOST: 'studio_mongodb',
        DB_PORT:'27017',
        DB_NAME: 'conversations',

        GATEWAY_SERVICES: 'http://api-gateway',
        LLM_GATEWAY_SERVICES: 'http://llm-gateway/',

        CORS_ENABLED:'true',
        CORS_API_WHITELIST: 'https://'+domain,

	      MAX_SUBTITLE_VERSION:5,
        EXPRESS_SIZE_FILE_MAX:'1gb',
        AXIOS_SIZE_FILE_MAX:'1000000000',

        SMTP_HOST:'',
        SMTP_PORT:'',
        SMTP_SECURE:'',
        SMTP_REQUIRE_TLS:'',
        SMTP_AUTH:'',
        SMTP_PSWD:'',
        NO_REPLY_EMAIL:'',

        CM_JWT_SECRET:'jwt_secret',
        CM_REFRESH_SECRET:'jwt_refresh_secret',

        DISABLE_USER_CREATION:'false',
        EXPORT_TEMPLATE: '',
        WEBSERVER_HTTP_PORT: 80,

        ORGANIZATION_DEFAULT_PERMISSIONS: 'upload,summary,session',

        SESSION_API_ENDPOINT: 'http://session-api/v1',
        BROKER_HOST: 'session-broker',
        BROKER_PORT: 1883,
        BROKER_KEEPALIVE: 60,
        BROKER_PROTOCOL: 'mqtt',

        SUPER_ADMIN_EMAIL: 'superadmin@mail.fr',
        SUPER_ADMIN_PWD: 'superadmin'
      },
      networks: [
        'net_studio',
        'session_network',
        network,
      ],
    },
    studio_mongodb: {
      image: "mongo:6.0.2",
      deploy:{
        mode: "replicated",
        placement: {
          constraints: [
            "node.role==manager"
          ]
        },
        replicas: 1
      },
      volumes: [
        local_mount+'/database/db-cm-data:/data/db',
      ],
      networks: [
        "net_studio"
      ]
    },
  },
  networks: {
    net_studio: {
      external: true,
    },
    session_network: {
      external: true,
    },
  },
};

std.mergePatch(service, patch)


