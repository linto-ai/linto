local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local domain = std.extVar('LINTO_DOMAIN');
local service = base.Service(config);

local theme = std.extVar('LINTO_FRONT_THEME');
local enable_session_studio = std.extVar('ENABLE_SESSION_STUDIO') == "true";

local patch = {
  services: {
    [config.service_name]: {
      environment: {
        VUE_APP_PUBLIC_MEDIA: '/cm-api/media',
        VUE_APP_CONVO_API: '/cm-api/api',
        VUE_APP_CONVO_AUTH: '/cm-api/auth',
        VUE_APP_WEBSOCKET_SERVER: "wss://" + domain,
        VUE_APP_WEBSOCKET_PATH: '/ws/socket.io',
        VUE_APP_TURN_SIZE: 2000,
        VUE_APP_TURN_PER_PAGE: 10,
        VUE_APP_MAX_CARACTERS_PER_PAGE: 20000,
        VUE_APP_DISABLE_USER_CREATION: 'false',
        VUE_APP_THEME: theme,
        VUE_APP_NAME: 'LinTO studio',
        VUE_APP_SESSION_WS: 'https://' + domain,
        VUE_APP_SESSION_WS_PATH: '/cm-api/socket.io',
        VUE_APP_EXPERIMENTAL_HIGHLIGHT: 'false',
        VUE_APP_ENABLE_SESSION: std.toString(enable_session_studio),
      },
    },
  },
};

std.mergePatch(service, patch)
