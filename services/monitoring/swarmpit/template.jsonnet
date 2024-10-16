local base = import '../../../jsonnet/base.libsonnet';
local config = import 'config.jsonnet';
local service = base.Service(config);
local network = std.extVar('DOCKER_NETWORK');

local patch = {
  services: {
    [config.service_name]: {
      environment: [
        'SWARMPIT_DB=http://swarmpit_db:5984',
        'SWARMPIT_INFLUXDB=http://swarmpit_influxdb:8086',
      ],
      volumes: [
        '/var/run/docker.sock:/var/run/docker.sock:ro',
      ],
      networks: [
        '$DOCKER_NETWORK',
        'net'
      ],
    },
    swarmpit_db: {
      image: 'couchdb:2.3.0',
      volumes: [
        'swarmpit_db-data:/opt/couchdb/data',
      ],
      networks: [
        'net',
      ],
      deploy: {
        resources: {
          limits: {
            cpus: '0.30',
            memory: '512M',
          },
          reservations: {
            cpus: '0.15',
            memory: '256M',
          },
        },
        placement: {
          constraints: [
            'node.role == manager', //'node.labels.swarmpit.db-data == true',
          ],
        },
      },
    },
    swarmpit_influxdb: {
      image: 'influxdb:1.7',
      volumes: [
        'swarmpit_influx-data:/var/lib/influxdb',
      ],
      networks: [
        'net',
      ],
      deploy: {
        resources: {
          reservations: {
            cpus: '0.3',
            memory: '128M',
          },
          limits: {
            cpus: '0.6',
            memory: '512M',
          },
        },
        placement: {
          constraints: [
            'node.role == manager', //'node.labels.swarmpit.influx-data == true',
          ],
        },
      },
    },
    swarmpit_agent: {
      image: 'swarmpit/agent:latest',
      environment: [
        'DOCKER_API_VERSION=1.35',
        'EVENT_ENDPOINT=http://swarmpit:8080/events',
        'HEALTH_CHECK_ENDPOINT=http://swarmpit:8080/version'
      ],
      volumes: [
        '/var/run/docker.sock:/var/run/docker.sock:ro',
      ],
      networks: [
        'net',
      ],
      deploy: {
        mode: 'global',
        resources: {
          limits: {
            cpus: '0.10',
            memory: '64M',
          },
          reservations: {
            cpus: '0.05',
            memory: '32M',
          },
        },
      },
    },
  },
  networks: {
    net: {
      driver: 'overlay',
      attachable: true,
    },
  },
  volumes: {
    'swarmpit_db-data': {
      driver: 'local',
    },
    'swarmpit_influx-data': {
      driver: 'local',
    },
  },
};

std.mergePatch(service, patch)
