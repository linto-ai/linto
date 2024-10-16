local domain = std.extVar('LINTO_DOMAIN');
local labels = import 'labels.libsonnet';

{
  deploy(config)::
    {
      [if (config.expose_with_traefik || config.expose_with_api_gateway) then 'labels']: std.prune(
        labels.labels(config)
      ),
      mode: 'replicated',
      replicas: config.replicas,
      [if std.length(config.reserve_cpu) > 0 || std.length(config.reserve_memory) > 0 || std.length(config.limit_cpu) > 0 || std.length(config.limit_memory) > 0 then 'resources']: {
        [if std.length(config.reserve_cpu) > 0 || std.length(config.reserve_memory) > 0 then 'reservations']: {
          [if std.length(config.reserve_cpu) > 0 then 'cpus']: config.reserve_cpu,
          [if std.length(config.reserve_memory) > 0 then 'memory']: config.reserve_memory,
        },
        [if std.length(config.limit_cpu) > 0 || std.length(config.limit_memory) > 0 then 'limits']: {
          [if std.length(config.limit_cpu) > 0 then 'cpus']: config.limit_cpu,
          [if std.length(config.limit_memory) > 0 then 'memory']: config.limit_memory,
        },
      },
      [if std.length(config.swarm_node_label_constraints) > 0 || std.length(config.swarm_node_role_constraints) > 0 then 'placement']: {
        constraints: std.prune([
          if std.length(config.swarm_node_label_constraints) > 0 then
            'node.labels.' + constraint[0] + '==' + constraint[1]
          for constraint in config.swarm_node_label_constraints
        ] + [
          if std.length(config.swarm_node_role_constraints) > 0 then
            'node.role==' + config.swarm_node_role_constraints,
        ]),
      },
    },
}

{
  healthcheck(config)::
    {
      //test: ["CMD", "curl", "-f", "http://localhost/health"],
      interval: config.healthcheck_interval,
      timeout: config.healthcheck_timeout,
      retries: config.healthcheck_retries,
      start_period: config.healthcheck_start_period,
    },
}
