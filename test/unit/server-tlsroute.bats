#!/usr/bin/env bats

load _helpers

@test "server/gateway/tlsroute: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-tlsroute.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/gateway/tlsroute: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml  \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml  \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/gateway/tlsroute: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-tlsroute.yaml  \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'injector.externalVaultAddr=http://openbao-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/gateway/tlsroute: checking host entry gets added" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.gateway.tlsRoute.hosts[0]=test.com' \
      . | tee /dev/stderr |
      yq  -r '.spec.hostnames[0]' | tee /dev/stderr)
  [ "${actual}" = 'test.com' ]
}

@test "server/gateway/tlsroute: openbao backend should be added" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.gateway.tlsRoute.hosts[0].host=test.com' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].backendRefs[0].name  | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

}

@test "server/gateway/tlsroute: labels gets added to object" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.gateway.tlsRoute.labels.traffic=external' \
      --set 'server.gateway.tlsRoute.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

@test "server/gateway/tlsroute: annotations added to object - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.gateway.tlsRoute.annotations=kubernetes.io/ingress.class: nginx' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/gateway/tlsroute: annotations added to object - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set server.gateway.tlsRoute.annotations."kubernetes\.io/ingress\.class"=nginx \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/gateway/tlsroute: uses active service when ha by default - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao-active" ]
}

@test "server/gateway/tlsroute: uses regular service when configured with ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.gateway.tlsRoute.activeService=false' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/tlsroute: uses regular service when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/tlsroute: uses regular service when not ha and activeService is true - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-tlsroute.yaml \
      --set 'server.gateway.tlsRoute.enabled=true' \
      --set 'server.gateway.tlsRoute.activeService=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}
