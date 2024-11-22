local tag = std.extVar('LINTO_IMAGE_TAG');
local repo = std.extVar('DOCKER_REGISTRY');
local domain = std.extVar('LINTO_DOMAIN');

local expose_with_traefik = std.extVar('EXPOSE_TRAEFIK') == "true";
local expose_with_gateway = std.extVar('EXPOSE_GATEWAY') == "true";


{
  //Generals
  build_me: true,  //Set to false to disable this build as a YAML file in ./running dir
  service_name: 'stt-kaldi-french-streaming',
  image: 'lintoai/linto-stt-kaldi:' + tag,
  reserve_memory: '',  //128M
  reserve_cpu: '',  //0.5
  limit_cpu: '',  //1
  limit_memory: '',  //512M
  replicas: 1,

  //Main blocks
  use_env_file: '',  //Set to specified env file (.dockerenv) or leave blank
  expose_with_traefik: expose_with_traefik, // TODO : set this to false after API GATEWAY tests
  healthcheck: true,
  expose_with_api_gateway: expose_with_gateway,

  //Traefik
  traefik_endpoint: '/stt-kaldi-french-streaming',
  traefik_strip_prefix: '/stt-kaldi-french-streaming',
  traefik_server_port: 80,
  traefik_domain: domain,
  use_basic_auth: true,

  //Healthcheck
  healthcheck_interval: '15s',
  healthcheck_timeout: '10s',
  healthcheck_retries: 4,
  healthcheck_start_period: '10s',
  restart_policy: false,
  restart_condition: 'on-failure',
  restart_delay: '5s',
  restart_max_attempts: 3,

  //swarm node label constraints
  swarm_node_label_constraints: [],  //[['ip', 'ingress'], ['mongo', true]...]

  //swarm node role constraints
  swarm_node_role_constraints: '',  // worker, manager, or leave blank for none

  //API Gateway
  gateway_server_port: 80,
  gateway_server_desc:{ en: "Linto streaming service",fr:"Service de streaming Linto"},
  gateway_server_scope: 'llm',

  gateway_define_endpoints: [
    {
      endpoint: 'stt-kaldi-french-streaming',
      middlewares_order: 'logs',
      middlewares: [
        { name: 'logs', params: { debug: '*' } }
      ],
    },
  ],
  //Override command
  command: [],
}