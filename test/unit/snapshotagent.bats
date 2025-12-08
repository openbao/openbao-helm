#!/usr/bin/env bats

load _helpers

@test "snapshotagent/cronjob: disabled by default" {
  cd `chart_dir`
  local
  local actual=$( (helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    . || echo "---") | tee /dev/stderr |
    yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "snapshotagent/cronjob: namespace:" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'global.namespace=bar' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "snapshotagent/cronjob: annotations:" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.annotations.example\.com/foo=bar' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.metadata.annotations["example.com/foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "snapshotagent/cronjob: schedule:" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.schedule=0 0 0 0 0' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.schedule' | tee /dev/stderr)
  [ "${actual}" = "0 0 0 0 0" ]

}

@test "snapshot/cronjob: extraVolumes" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.extraVolumes[0].name=my-volume' \
    --set 'snapshotAgent.extraVolumes[0].emptyDir={}' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.jobTemplate.spec.template.spec.volumes[1].name' | tee /dev/stderr)
  [ "${actual}" = "my-volume" ]
}

@test "snapshot/cronjob: image overwrite" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.image.repository=my-repo' \
    --set 'snapshotAgent.image.tag=my-tag' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.jobTemplate.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "my-repo:my-tag" ]
}

@test "snapshot/serviceaccount: disabled" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-serviceaccount.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.serviceAccount.create=false' \
    --namespace foo \
    . | tee /dev/stderr |
    yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.serviceAccount.create=false' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.jobTemplate.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "default" ]
}

@test "snapshot/serviceaccount: own name" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.serviceAccount.create=true' \
    --set 'snapshotAgent.serviceAccount.name=my-sa' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.jobTemplate.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "my-sa" ]
}

@test "snapshot/configmap: configuration" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.config.s3Host=s3.us-west-1.amazonaws.com' \
    --set 'snapshotAgent.config.s3Bucket=my-bucket' \
    --set 'snapshotAgent.config.s3Uri=s3://my-bucket' \
    --set 'snapshotAgent.config.s3ExpireDays=1' \
    --set 'snapshotAgent.config.s3CredentialsSecret=creds' \
    --set 'snapshotAgent.config.s3CmdExtraFlags=-q' \
    --set 'snapshotAgent.config.baoAuthPath=jwt' \
    --set 'snapshotAgent.config.baoRole=backup' \
    --set 'snapshotAgent.config.baoAddr=http://openbao.openbao.svc:8200' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data' | sha256sum | tee /dev/stderr)
  [ "${actual}" = "fc5538001af4cfe6bbe4d48cc9f13dc4c908a1029960e60e372af7cb56926c43  -" ]
}
