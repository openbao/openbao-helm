#!/usr/bin/env bats

load _helpers

render_self_init_configmap() {
  helm template \
      --show-only templates/server-self-init-configmap.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.selfInit.enabled=true' \
      --set-string 'server.selfInit.config=initialize "{{ .Release.Name }}_platform_access" {}' \
      "$@" .
}

@test "server/SelfInit ConfigMap: disabled when self-init does not apply" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-self-init-configmap.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-self-init-configmap.yaml \
      --set 'server.dev.enabled=true' \
      --set 'server.selfInit.enabled=true' \
      --set-string 'server.selfInit.config=initialize "platform_access" {}' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-self-init-configmap.yaml \
      --set 'global.externalVaultAddr=http://openbao-outside' \
      --set 'server.selfInit.enabled=true' \
      --set-string 'server.selfInit.config=initialize "platform_access" {}' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/SelfInit ConfigMap: includes autopilot cleanup and templated config" {
  cd `chart_dir`
  local actual=$(render_self_init_configmap \
      --set 'server.ha.replicas=5' \
      --set 'server.selfInit.job.autopilot.deadServerLastContactThreshold=2m' \
      --set 'server.selfInit.job.autopilot.serverStabilizationTime=15s' | tee /dev/stderr |
      yq -r '.data["self-init.hcl"]' | tee /dev/stderr)

  [[ "${actual}" == *'initialize "openbao_self_init_autopilot"'* ]]
  [[ "${actual}" == *'path = "sys/storage/raft/autopilot/configuration"'* ]]
  [[ "${actual}" == *'cleanup_dead_servers = true'* ]]
  [[ "${actual}" == *'dead_server_last_contact_threshold = "2m"'* ]]
  [[ "${actual}" == *'server_stabilization_time = "15s"'* ]]
  [[ "${actual}" == *'min_quorum = 5'* ]]
  [[ "${actual}" == *'initialize "release-name_platform_access" {}'* ]]
}

@test "server/SelfInit ConfigMap: autopilot cleanup can be overridden or skipped" {
  cd `chart_dir`
  local override=$(render_self_init_configmap \
      --set 'server.ha.replicas=5' \
      --set 'server.selfInit.job.autopilot.minQuorum=3' \
      --set-string 'server.selfInit.config=initialize "platform_access" {}' | tee /dev/stderr |
      yq -r '.data["self-init.hcl"]' | tee /dev/stderr)
  [[ "${override}" == *'min_quorum = 3'* ]]

  local disabled=$(render_self_init_configmap \
      --set 'server.selfInit.job.autopilot.enabled=false' \
      --set-string 'server.selfInit.config=initialize "platform_access" {}' | tee /dev/stderr |
      yq -r '.data["self-init.hcl"]' | tee /dev/stderr)
  [[ "${disabled}" != *'initialize "openbao_self_init_autopilot"'* ]]
  [[ "${disabled}" == *'initialize "platform_access" {}'* ]]
}

@test "server/SelfInit ConfigMap: validates HA Raft configuration" {
  cd `chart_dir`
  run helm template \
      --show-only templates/server-self-init-configmap.yaml \
      --set 'server.selfInit.enabled=true' \
      --set-string 'server.selfInit.config=initialize "platform_access" {}' \
      .
  [ "$status" -ne 0 ]
  [[ "$output" == *'server.selfInit.enabled requires server.ha.enabled=true and server.ha.raft.enabled=true'* ]]

  run helm template \
      --show-only templates/server-self-init-configmap.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.ha.raft.config.storage=raft' \
      --set 'server.selfInit.enabled=true' \
      --set-string 'server.selfInit.config=initialize "platform_access" {}' \
      .
  [ "$status" -ne 0 ]
  [[ "$output" == *'server.selfInit.config requires server.ha.raft.config to be a string'* ]]
}
