// Canonical docker swarm service
local functions = import 'functions.libsonnet';
local network = std.extVar('DOCKER_NETWORK');
{
  Service(config):: {
    version: '3.7',
    services: {
      [config.service_name]: {
        image: config.image,
        networks: [
          network,
        ],
        [if std.length(config.use_env_file) > 0 then 'env_file']: config.use_env_file,
        deploy: functions.deploy(config),
        [if (config.healthcheck) then 'healthcheck']: std.prune(
          functions.healthcheck(config)
        ),
        [if (std.length(config.command) > 0) then 'command']: config.command,
      },
    },
    networks: {
      [network]: {
        external: true,
      },
    },
  },
}
