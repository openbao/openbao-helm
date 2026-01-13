#!/usr/bin/env bats

load _helpers

@test "server/gateway/httproute: show warning" {
  cd `chart_dir`

  local actual=$(helm install \
      --dry-run --generate-name \
      --set 'server.gateway.httpRoute.enabled=true' \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      grep "WARNING: Terminating TLS before reaching the OpenBao Server is not recommended" | wc -c | tee /dev/stderr)
  [ "${actual}" != "0" ]
}

