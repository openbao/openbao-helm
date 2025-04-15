#!/usr/bin/env bats

load _helpers

@test "csi/Agent-ConfigMap: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-agent-configmap.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "csi/Agent-ConfigMap: name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-agent-configmap.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-openbao-csi-provider-agent-config" ]
}

@test "csi/Agent-ConfigMap: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-agent-configmap.yaml \
      --set "csi.enabled=true" \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/csi-agent-configmap.yaml \
      --set "csi.enabled=true" \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/Agent-ConfigMap: OpenBao addr not affected by injector setting" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-agent-configmap.yaml \
      --set "csi.enabled=true" \
      --release-name not-external-test \
      --set 'injector.externalVaultAddr=http://openbao-outside' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${actual}" | grep "http://not-external-test-openbao.default.svc:8200"
}

@test "csi/Agent-ConfigMap: OpenBao addr correctly set for externalVaultAddr" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-agent-configmap.yaml \
      --set "csi.enabled=true" \
      --set 'global.externalVaultAddr=http://openbao-outside' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${actual}" | grep "http://openbao-outside"
}

@test "csi/Agent-ConfigMap: OpenBao addr correctly set for externalBaoAddr" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-agent-configmap.yaml \
      --set "csi.enabled=true" \
      --set 'global.externalBaoAddr=http://openbao-outside' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${actual}" | grep "http://openbao-outside"
}

@test "csi/Agent-ConfigMap: OpenBao addr correctly set for externalBaoAddr, verify if externalBaoAddr takes precendece over externalVaultAddr" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-agent-configmap.yaml \
      --set "csi.enabled=true" \
      --set 'global.externalBaoAddr=http://openbao-outside' \
      --set 'global.externalVaultAddr=http://vault-outside' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${actual}" | grep "http://openbao-outside"
}