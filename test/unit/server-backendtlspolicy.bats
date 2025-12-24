#!/usr/bin/env bats

load _helpers

@test "server/gateway/tlspolicy: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml  \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml  \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/gateway/tlspolicy: has api version" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml  \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.apiVersion | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/gateway/tlspolicy: disable by tlsDisable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml  \
      --set 'global.tlsDisable=true' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      . || echo "---" | tee /dev/stderr |
      yq -r 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/gateway/tlspolicy: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-backendtlspolicy.yaml  \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'injector.externalVaultAddr=http://openbao-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/gateway/tlspolicy: labels gets added to object" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.gateway.tlsPolicy.labels.traffic=external' \
      --set 'server.gateway.tlsPolicy.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

@test "server/gateway/tlspolicy: annotations added to object - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.gateway.tlsPolicy.annotations=kubernetes.io/ingress.class: nginx' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/gateway/tlspolicy: annotations added to object - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set server.gateway.tlsPolicy.annotations."kubernetes\.io/ingress\.class"=nginx \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/gateway/tlspolicy: uses active service when ha by default - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.targetRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao-active" ]
}

@test "server/gateway/tlspolicy: uses regular service when configured with ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.gateway.tlsPolicy.activeService=false' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.targetRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/tlspolicy: uses regular service when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.targetRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/tlspolicy: uses regular service when not ha and activeService is true - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.gateway.tlsPolicy.activeService=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.targetRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/tlspolicy: validation hostname" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.gateway.tlsPolicy.activeService=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.validation.hostname' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao" ]
}

@test "server/gateway/tlspolicy: validation settings" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.gateway.tlsPolicy.activeService=true' \
      --set 'server.service.enabled=true' \
      --set 'server.gateway.tlsPolicy.validation.caCertificateRefs.name=ca-certs' \
      . | tee /dev/stderr |
      yq -r '.spec.validation.caCertificateRefs.name' | tee /dev/stderr)
  [ "${actual}" = "ca-certs" ]
}

@test "server/gateway/tlspolicy: specify target ref" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-backendtlspolicy.yaml \
      --set 'global.tlsDisable=false' \
      --set 'server.gateway.tlsPolicy.enabled=true' \
      --set 'server.gateway.tlsPolicy.activeService=true' \
      --set 'server.service.enabled=true' \
      --set 'server.gateway.tlsPolicy.targetRefs[0].name=some-target' \
      . | tee /dev/stderr |
      yq -r '.spec.targetRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "some-target" ]
}

