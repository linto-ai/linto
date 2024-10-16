local domain = std.extVar('LINTO_DOMAIN');
{
  labels(config)::
    local traefikDirectives = [
      'traefik.enable=true',
      if config.use_basic_auth then 'traefik.http.routers.' + config.service_name + '-router.middlewares=basic-auth@file',
      'traefik.http.routers.' + config.service_name + '-router.entrypoints=websecure',
      'traefik.http.routers.' + config.service_name + '-router.rule=Host(`' + config.traefik_domain + '`) && PathPrefix(`' + config.traefik_endpoint + '`)',
      'traefik.http.routers.' + config.service_name + '-router.tls=true',
      'traefik.http.services.' + config.service_name + '-service.loadbalancer.server.port=' + config.traefik_server_port,
      
      // Conditionally add the certresolver line based on DEPLOYMENT_MODE
      if std.extVar('DEPLOYMENT_MODE') != 'LOCALHOST' then
        'traefik.http.routers.' + config.service_name + '-router.tls.certresolver=leresolver',

      if (std.length(config.traefik_strip_prefix) > 0) then
        'traefik.http.middlewares.' + config.service_name + '-stripprefix.stripPrefix.prefixes=' + config.traefik_endpoint,
      if (std.length(config.traefik_strip_prefix) > 0) then
        'traefik.http.routers.' + config.service_name + '-router.middlewares=' + config.service_name + '-stripprefix@docker',
    ];

    local apiGatewayDirectives = [
      'linto.gateway.enable=true',
      'linto.gateway.port=' + config.gateway_server_port,
      'linto.gateway.desc=' + config.gateway_server_desc,
      'linto.gateway.scope=' + config.gateway_server_scope,
    ];

    local define_endpoints = [std.join("/", std.flattenArrays([
      ['linto.gateway.endpoints='],
      [
          define_endpoint.endpoint+',',
        for define_endpoint in config.gateway_define_endpoints
        if std.objectHas(define_endpoint, 'endpoint')
      ]
    ]))];

    local define_middleware = std.uniq(std.sort(std.flattenArrays([
        ['linto.gateway.endpoint.'+define_endpoint.endpoint+'.middlewares='+define_endpoint.middlewares_order]
      for define_endpoint in config.gateway_define_endpoints
      if std.objectHas(define_endpoint, 'middlewares_order')
    ])));

    local define_middleware_param = std.uniq(std.sort(std.flattenArrays([
        ['linto.gateway.endpoint.'+define_endpoint.endpoint+'.middlewares.'+middlewares.name+'.'+paramsKey+'='+middlewares.params[paramsKey]]
      for define_endpoint in config.gateway_define_endpoints
      if std.objectHas(define_endpoint, 'middlewares')
      for middlewares in define_endpoint.middlewares
      if std.objectHas(middlewares, 'params')
      for paramsKey in std.objectFields(middlewares.params)
    ])));

    std.prune(
      [
        if config.expose_with_traefik then
          traefikItem
        for traefikItem in traefikDirectives
      ] + [
        if config.expose_with_api_gateway then
          apiGatewayDirective
        for apiGatewayDirective in apiGatewayDirectives
      ] +
      if config.expose_with_api_gateway then
        define_endpoints +
        define_middleware +
        define_middleware_param
      else []
    ),
}