#!/usr/bin/env bats

load _helpers

render_self_init() {
  helm template \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.selfInit.enabled=true' \
      --set-string 'server.selfInit.config=initialize "platform_access" {}' \
      "$@" .
}

@test "server/SelfInit Job: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-self-init-job.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/SelfInit Job: renders GitOps-safe bootstrap resources" {
  cd `chart_dir`
  local job=$(render_self_init \
      --show-only templates/server-self-init-job.yaml \
      --set 'server.selfInit.job.holdSeconds=42' | tee /dev/stderr)

  local name=$(echo "${job}" | yq -r '.metadata.name' | tee /dev/stderr)
  [[ "${name}" =~ ^release-name-openbao-self-init-[0-9a-f]{10}$ ]]
  [ "$(echo "${job}" | yq -r '.kind')" = "Job" ]
  [ "$(echo "${job}" | yq -r '.spec | has("ttlSecondsAfterFinished")')" = "false" ]

  local args=$(echo "${job}" | yq -r '.spec.template.spec.containers[0].args[0]' | tee /dev/stderr)
  [[ "${args}" == *'bao server -config=/tmp/storageconfig.hcl'* ]]
  [[ "${args}" == *'release-name-openbao-0.release-name-openbao-internal.default.svc:8200'* ]]
  [[ "${args}" == *'skipping self-init bootstrap'* ]]
  [[ "${args}" == *'sleep 42'* ]]

  local ttl=$(render_self_init \
      --show-only templates/server-self-init-job.yaml \
      --set 'server.selfInit.job.ttlSecondsAfterFinished=123' | tee /dev/stderr |
      yq -r '.spec.ttlSecondsAfterFinished' | tee /dev/stderr)
  [ "${ttl}" = "123" ]

  local changed_name=$(render_self_init \
      --show-only templates/server-self-init-job.yaml \
      --set-string 'server.selfInit.config=initialize "different_platform_access" {}' | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${name}" != "${changed_name}" ]

  local service=$(render_self_init \
      --show-only templates/server-self-init-service.yaml \
      --set 'server.selfInit.job.holdSeconds=42' | tee /dev/stderr)
  [ "$(echo "${service}" | yq -r '.spec.clusterIP')" = "None" ]
  [ "$(echo "${service}" | yq -r '.spec.selector.component')" = "self-init" ]

  local job_generation=$(echo "${job}" | yq -r '.spec.template.metadata.labels["openbao.org/self-init-generation"]')
  local service_generation=$(echo "${service}" | yq -r '.spec.selector["openbao.org/self-init-generation"]')
  [ "${service_generation}" = "${job_generation}" ]
}

@test "server/SelfInit Job: keeps bootstrap config separate from StatefulSet config" {
  cd `chart_dir`
  local job_config=$(render_self_init \
      --show-only templates/server-self-init-job-configmap.yaml | tee /dev/stderr |
      yq -r '.data["extraconfig-from-values.hcl"]' | tee /dev/stderr)
  [[ "${job_config}" == *'storage "raft"'* ]]
  [[ "${job_config}" != *'retry_join'* ]]
  [[ "${job_config}" != *'initialize "platform_access"'* ]]

  local server_config=$(render_self_init \
      --show-only templates/server-config-configmap.yaml | tee /dev/stderr |
      yq -r '.data["extraconfig-from-values.hcl"]' | tee /dev/stderr)
  [[ "${server_config}" == *'leader_api_addr = "http://release-name-openbao-self-init.default.svc:8200"'* ]]
  [[ "${server_config}" == *'leader_api_addr = "http://release-name-openbao-0.release-name-openbao-internal.default.svc:8200"'* ]]
  [[ "${server_config}" == *'leader_api_addr = "http://release-name-openbao-2.release-name-openbao-internal.default.svc:8200"'* ]]
  [[ "${server_config}" != *'initialize "platform_access"'* ]]

  local statefulset=$(render_self_init \
      --show-only templates/server-statefulset.yaml \
      --set 'server.podManagementPolicy=OrderedReady' | tee /dev/stderr)
  [ "$(echo "${statefulset}" | yq -r '.spec.podManagementPolicy')" = "Parallel" ]
  [ "$(echo "${statefulset}" | yq -r '(.spec.template.spec.volumes // []) | map(select(.name == "self-init-config")) | length')" = "0" ]
  [[ "$(echo "${statefulset}" | yq -r '.spec.template.spec.containers[0].args[0]')" != *'/openbao/self-init/self-init.hcl'* ]]
}

@test "server/SelfInit Job: inherits user server volumes and mounts" {
  cd `chart_dir`
  local job=$(render_self_init \
      --show-only templates/server-self-init-job.yaml \
      --set 'server.extraVolumes[0].name=seal-material' \
      --set 'server.extraVolumes[0].type=secret' \
      --set 'server.extraVolumes[0].path=/openbao/seal' \
      --set 'server.volumes[0].name=custom-seal' \
      --set 'server.volumes[0].secret.secretName=custom-seal' \
      --set 'server.volumeMounts[0].name=custom-seal' \
      --set 'server.volumeMounts[0].mountPath=/openbao/custom-seal' | tee /dev/stderr)

  [ "$(echo "${job}" | yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-seal-material").secret.secretName')" = "seal-material" ]
  [ "$(echo "${job}" | yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-seal-material").mountPath')" = "/openbao/seal/seal-material" ]
  [ "$(echo "${job}" | yq -r '.spec.template.spec.volumes[] | select(.name == "custom-seal").secret.secretName')" = "custom-seal" ]
  [ "$(echo "${job}" | yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "custom-seal").mountPath')" = "/openbao/custom-seal" ]
}
