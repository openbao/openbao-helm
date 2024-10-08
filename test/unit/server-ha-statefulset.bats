#!/usr/bin/env bats

load _helpers

@test "server/ha-StatefulSet: enable with server.ha.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-StatefulSet: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.enabled=false' \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-StatefulSet: disable with injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'injector.externalVaultAddr=http://openbao-outside' \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-StatefulSet: image defaults to server.image.repository:tag" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=1.2.3' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "quay.io/foo:1.2.3" ]
}

@test "server/ha-StatefulSet: image tag defaults to latest" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "quay.io/foo:latest" ]
}

#--------------------------------------------------------------------
# TLS

@test "server/ha-StatefulSet: tls disabled" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.tlsDisable=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "http://127.0.0.1:8200" ]
}

@test "server/ha-StatefulSet: tls enabled" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "https://127.0.0.1:8200" ]
}

#--------------------------------------------------------------------
# updateStrategy

@test "server/ha-StatefulSet: OnDelete updateStrategy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "OnDelete" ]
}

@test "server/ha-StatefulSet: RollingUpdate updateStrategy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.updateStrategyType="RollingUpdate"' \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "RollingUpdate" ]
}

#--------------------------------------------------------------------
# affinity

@test "server/ha-StatefulSet: default affinity" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.affinity' | tee /dev/stderr)
  [ "${actual}" != "null" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.affinity=' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.affinity' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

#--------------------------------------------------------------------
# replicas

@test "server/ha-StatefulSet: default replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "3" ]
}

@test "server/ha-StatefulSet: custom replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=10' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "10" ]
}

@test "server/ha-StatefulSet: zero replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=0' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "0" ]
}

@test "server/ha-StatefulSet: invalid value for replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=null' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "3" ]
}

#--------------------------------------------------------------------
# resources

@test "server/ha-StatefulSet: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ha-StatefulSet: custom resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.requests.memory=256Mi' \
      --set 'server.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.limits.memory=256Mi' \
      --set 'server.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]
}

#--------------------------------------------------------------------
# extraVolumes

@test "server/ha-StatefulSet: adds extra volume" {
  cd `chart_dir`
  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.configMap.name' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(echo $object |
      yq -r '.configMap.secretName' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/openbao/userconfig/foo" ]
}

@test "server/ha-StatefulSet: adds extra volume custom mount path" {
  cd `chart_dir`
  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      --set 'server.extraVolumes[0].path=/custom/path' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/custom/path/foo" ]
}

@test "server/ha-StatefulSet: adds extra secret volume custom mount path" {
  cd `chart_dir`

  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      --set 'server.extraVolumes[0].path=/custom/path' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/custom/path/foo" ]
}

@test "server/ha-StatefulSet: adds extra secret volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=secret' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.secret.name' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(echo $object |
      yq -r '.secret.secretName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/openbao/userconfig/foo" ]
}

#--------------------------------------------------------------------
# extraEnvironmentVars

@test "server/ha-StatefulSet: set extraEnvironmentVars" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraEnvironmentVars.FOO=bar' \
      --set 'server.extraEnvironmentVars.FOOBAR=foobar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="FOO")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "bar" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="FOOBAR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "foobar" ]
}

#--------------------------------------------------------------------
# extraSecretEnvironmentVars

@test "server/ha-StatefulSet: set extraSecretEnvironmentVars" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraSecretEnvironmentVars[0].envName=ENV_FOO_0' \
      --set 'server.extraSecretEnvironmentVars[0].secretName=secret_name_0' \
      --set 'server.extraSecretEnvironmentVars[0].secretKey=secret_key_0' \
      --set 'server.extraSecretEnvironmentVars[1].envName=ENV_FOO_1' \
      --set 'server.extraSecretEnvironmentVars[1].secretName=secret_name_1' \
      --set 'server.extraSecretEnvironmentVars[1].secretKey=secret_key_1' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="ENV_FOO_0")) | .[] .valueFrom.secretKeyRef.name' | tee /dev/stderr)
  [ "${value}" = "secret_name_0" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="ENV_FOO_0")) | .[] .valueFrom.secretKeyRef.key' | tee /dev/stderr)
  [ "${value}" = "secret_key_0" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="ENV_FOO_1")) | .[] .valueFrom.secretKeyRef.name' | tee /dev/stderr)
  [ "${value}" = "secret_name_1" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="ENV_FOO_1")) | .[] .valueFrom.secretKeyRef.key' | tee /dev/stderr)
  [ "${value}" = "secret_key_1" ]
}

#--------------------------------------------------------------------
# BAO_API_ADDR renders

@test "server/ha-StatefulSet: api addr renders to Pod IP by default" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_API_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = 'http://$(POD_IP):8200' ]
}

@test "server/ha-StatefulSet: api addr is configurable" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.apiAddr="https://example.com:8200"' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_API_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "https://example.com:8200" ]
}

#--------------------------------------------------------------------
# BAO_CLUSTER_ADDR renders

@test "server/ha-StatefulSet: clusterAddr not set" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_CLUSTER_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = 'https://$(HOSTNAME).release-name-openbao-internal:8201' ]
}

@test "server/ha-StatefulSet: clusterAddr set to null" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
       --set 'server.ha.clusterAddr=null' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_CLUSTER_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = 'https://$(HOSTNAME).release-name-openbao-internal:8201' ]
}

@test "server/ha-StatefulSet: clusterAddr set to custom url" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
       --set 'server.ha.clusterAddr=https://test.example.com:8201' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_CLUSTER_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = 'https://test.example.com:8201' ]
}

@test "server/ha-StatefulSet: clusterAddr set to custom url with environment variable" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
       --set 'server.ha.clusterAddr=http://$(HOSTNAME).release-name-openbao-internal:8201' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_CLUSTER_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = 'http://$(HOSTNAME).release-name-openbao-internal:8201' ]
}

@test "server/ha-StatefulSet: clusterAddr gets quoted" {
  cd `chart_dir`
  local customUrl='http://$(HOSTNAME).release-name-openbao-internal:8201'
  local rendered=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set "server.ha.clusterAddr=${customUrl}" \
      . | tee /dev/stderr | \
      grep -F "${customUrl}" | tee /dev/stderr)

local value=$(echo $rendered |
      yq -Y '.' | tee /dev/stderr)
  [ "${value}" = 'value: "http://$(HOSTNAME).release-name-openbao-internal:8201"' ]
}

#--------------------------------------------------------------------
# BAO_RAFT_NODE_ID renders

@test "server/ha-StatefulSet: raft node ID renders" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.ha.raft.setNodeId=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="BAO_RAFT_NODE_ID")) | .[] .valueFrom.fieldRef.fieldPath' | tee /dev/stderr)
  [ "${value}" = "metadata.name" ]
}

#--------------------------------------------------------------------
# storage class

@test "server/ha-StatefulSet: no storage by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]
}


@test "server/ha-StatefulSet: cant set data storage" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      --set 'server.dataStorage.storageClass=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ha-StatefulSet: can set storageClass" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.dataStorage.enabled=false' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.auditStorage.storageClass=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].spec.storageClassName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}

@test "server/ha-StatefulSet: can disable storage" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=false' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "server/ha-StatefulSet: can mount audit" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "audit")' | tee /dev/stderr)
}

@test "server/ha-StatefulSet: no data storage" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=false' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

#--------------------------------------------------------------------
# topologySpreadConstraints

@test "server/ha-StatefulSet: topologySpreadConstraints is null by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .topologySpreadConstraints? == null' | tee /dev/stderr)
}

@test "server/ha-StatefulSet: topologySpreadConstraints can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.ha.enabled=true' \
      --set "server.topologySpreadConstraints[0].foo=bar,server.topologySpreadConstraints[1].baz=qux" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.topologySpreadConstraints == [{"foo": "bar"}, {"baz": "qux"}]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# tolerations

@test "server/ha-StatefulSet: tolerations not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .tolerations? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-StatefulSet: tolerations can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.tolerations=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.tolerations == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-StatefulSet: nodeSelector is not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ha-StatefulSet: specified nodeSelector as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.nodeSelector=testing' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "testing" ]
}

@test "server/ha-StatefulSet: nodeSelector can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set "server.nodeSelector.beta\.kubernetes\.io/arch=amd64" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector == {"beta.kubernetes.io/arch": "amd64"}' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# Security Contexts
@test "server/ha-StatefulSet: uid default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "100" ]
}

@test "server/ha-StatefulSet: uid configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.uid=2000' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

@test "server/ha-StatefulSet: gid default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsGroup' | tee /dev/stderr)
  [ "${actual}" = "1000" ]
}

@test "server/ha-StatefulSet: gid configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.gid=2000' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsGroup' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

@test "server/ha-StatefulSet: fsgroup default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.fsGroup' | tee /dev/stderr)
  [ "${actual}" = "1000" ]
}

@test "server/ha-StatefulSet: fsgroup configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.gid=2000' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.fsGroup' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

#--------------------------------------------------------------------
# OpenShift

@test "server/ha-statefulset: OpenShift - runAsUser disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.securityContext.runAsUser | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-statefulset: OpenShift - runAsGroup disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.securityContext.runAsGroup | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
