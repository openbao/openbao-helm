#!/usr/bin/env bats

load _helpers

@test "server/gateway/httproute: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-httproute.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/gateway/httproute: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.gateway.httpRoute.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/gateway/httproute: has api version" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.gateway.httpRoute.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.apiVersion | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/gateway/httproute: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'injector.externalVaultAddr=http://openbao-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/gateway/httproute: checking host entry gets added" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.hosts[0]=test.com' \
      . | tee /dev/stderr |
      yq  -r '.spec.hostnames[0]' | tee /dev/stderr)
  [ "${actual}" = 'test.com' ]
}

@test "server/gateway/httproute: openbao backend should be added" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.hosts[0]=test.com' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].backendRefs[0].name  | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

}

@test "server/gateway/httproute: labels gets added to object" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.labels.traffic=external' \
      --set 'server.gateway.httpRoute.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

@test "server/gateway/httproute: annotations added to object - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.annotations=kubernetes.io/ingress.class: nginx' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/gateway/httproute: annotations added to object - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set server.gateway.httpRoute.annotations."kubernetes\.io/ingress\.class"=nginx \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/gateway/httproute: uses active service when ha by default - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao-active" ]
}

@test "server/gateway/httproute: uses regular service when configured with ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.activeService=false' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/httproute: uses regular service when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/httproute: uses regular service when not ha and activeService is true - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.activeService=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/httproute: override matches" {
  cd `chart_dir`

  local path=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.matches.path.type=Exact' \
      --set 'server.gateway.httpRoute.matches.path.value=/test' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].matches[0].path' | tee /dev/stderr)
  local actual_type=$(echo "${path}" | yq -r '.type' | tee /dev/stderr)
  local actual_value=$(echo "${path}" | yq -r '.value' | tee /dev/stderr)
  [ "${actual_type}" = "Exact" ]
  [ "${actual_value}" = "/test" ]
}

@test "server/gateway/httproute: no filters" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].filters | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/gateway/httproute: filters" {
  cd `chart_dir`

  local filter=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.gateway.httpRoute.filters[0].type=RequestHeaderModifier' \
      --set 'server.gateway.httpRoute.filters[0].requestHeaderModifier.set[0].name=X-Forwarded-Proto' \
      --set 'server.gateway.httpRoute.filters[0].requestHeaderModifier.set[0].value=https' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].filters[0]' | tee /dev/stderr)
  local actual_type=$(echo "${filter}" | yq -r '.type' | tee /dev/stderr)
  local actual_name=$(echo "${filter}" | yq -r '.requestHeaderModifier.set[0].name' | tee /dev/stderr)
  local actual_value=$(echo "${filter}" | yq -r '.requestHeaderModifier.set[0].value' | tee /dev/stderr)
  [ "${actual_type}" = "RequestHeaderModifier" ]
  [ "${actual_name}" = "X-Forwarded-Proto" ]
  [ "${actual_value}" = "https" ]
}

@test "server/gateway/httproute: has matches" {
  cd `chart_dir`

  local path=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].matches[0].path' | tee /dev/stderr)
  local actual_type=$(echo "${path}" | yq -r '.type' | tee /dev/stderr)
  local actual_value=$(echo "${path}" | yq -r '.value' | tee /dev/stderr)
  [ "${actual_type}" = "PathPrefix" ]
  [ "${actual_value}" = "/" ]
}
