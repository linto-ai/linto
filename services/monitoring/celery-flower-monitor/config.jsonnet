local tag = std.extVar('LINTO_IMAGE_TAG');
local domain = std.extVar('LINTO_DOMAIN');

{
  //Generals
  build_me: true,  //Set to false to disable this build as a YAML file in ./running dir
  service_name: 'celery_flower_monitor',
  image: 'lintoai/linto-tasks-monitor:latest',
  reserve_memory: '',  //128M
  reserve_cpu: '',  //0.5
  limit_cpu: '',  //1
  limit_memory: '',  //512M
  replicas: 1,

  //Main blocks
  use_env_file: '',  //Set to specified env file (.dockerenv) or leave blank
  expose_with_traefik: true,
  healthcheck: false,
  expose_with_api_gateway: false,

  //Traefik
  traefik_endpoint: '/monitoring-celery',
  traefik_strip_prefix: '',
  traefik_domain: domain,
  traefik_server_port: 80,
  use_basic_auth: true,

  //Healthcheck
  healthcheck_interval: '15s',
  healthcheck_timeout: '10s',
  healthcheck_retries: 4,
  healthcheck_start_period: '10s',
  restart_policy: true,
  restart_condition: 'on-failure',
  restart_delay: '5s',
  restart_max_attempts: 3,

  //swarm node label constraints
  swarm_node_label_constraints: [],  //[['ip', 'ingress'], ['mongo', true]...]

  //swarm node role constraints
  swarm_node_role_constraints: '',  // worker, manager, or leave blank for none

  //API Gateway

  //Override command
  command: [
  ],
}
