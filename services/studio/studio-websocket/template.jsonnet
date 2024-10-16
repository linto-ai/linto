local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);

local patch = {
  services: {
    [config.service_name]: {
      environment: {
        COMPONENTS: 'WebServer,Websocket',
        CONVO_API: "http://studio-api/api",
        WEBSERVER_HTTP_PORT: 80,

        WEBSERVER_WS_PATH: '/socket.io',
      },
    },
  },
};

std.mergePatch(service, patch)
