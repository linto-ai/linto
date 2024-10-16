local config = import 'config.jsonnet';
local base = import '../../../jsonnet/base.libsonnet';
local service = base.Service(config);
local shared_mount = std.extVar("LINTO_SHARED_MOUNT");
local local_mount = std.extVar("LINTO_LOCAL_MOUNT");

local patch = {
  services: {
    [config.service_name]: {
      "ports": [
        "80:80",
        "8080:8080",
        "443:443"
      ],
      "volumes": [
        "/var/run/docker.sock:/var/run/docker.sock:ro",
        shared_mount + "/traefik/traefik.toml:/traefik.toml:ro",
        shared_mount + "/traefik/dynamic.toml:/dynamic.toml",
        shared_mount + "/certs/acme.json:/acme.json",
        shared_mount + "/certs-mkcert:/certs",
        local_mount + "/traefik/logs:/var/log/traefik",
      ],
    },
  },
};

std.mergePatch(service, patch)