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
        network,
        'session_network',
      ],
      expose: [
        "8889/udp",
        "1935"
      ],
      ports: [
        "8889:8889/udp",
        "1935:1935"
      ],
      environment: {
        BROKER_HOST: 'session-broker',
        BROKER_PORT: 1883,
        BROKER_KEEPALIVE: 60,
        BROKER_PROTOCOL: 'mqtt',

        DEBUG: 'transcriber*',
        STREAMING_PROXY_HOST: domain,
        STREAMING_PASSPHRASE: 'false',
        STREAMING_PROTOCOLS: 'SRT,RTMP,WS ',
        STREAMING_HEALTHCHECK_TCP:'9999',

        STREAMING_SRT_MODE: 'listener',
        STREAMING_SRT_UDP_PORT: '8889', # UDP port for SRT listener
        STREAMING_RTMP_TCP_PORT: '1935', # TCP port for RTMP listener
        STREAMING_WS_TCP_PORT:'8080', # TCP port for Websocket listener
        STREAMING_PROXY_SRT_UDP_PORT:'8889', # UDP port for SRT listener
        STREAMING_PROXY_RTMP_TCP_PORT:'1935', # TCP port for RTMP listener
        STREAMING_PROXY_WS_TCP_PORT:'443', # TCP port for Websocket listener
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
