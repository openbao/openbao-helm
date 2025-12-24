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

@test "snapshot/cronjob: resources" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.resources.requests.cpu=100m' \
    --set 'snapshotAgent.resources.requests.memory=100Mi' \
    --set 'snapshotAgent.resources.limits.cpu=1000m' \
    --set 'snapshotAgent.resources.limits.memory=1Gi' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.jobTemplate.spec.template.spec.containers[0].resources.requests.cpu' | tee /dev/stderr)
  [ "${actual}" = "100m" ]
}

@test "snapshot/cronjob: configuration: s3CredentialsSecret" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.s3CredentialsSecret=creds' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.jobTemplate.spec.template.spec.containers[0].env[] | select(.name == "AWS_SECRET_ACCESS_KEY") | .valueFrom.secretKeyRef.name' | tee /dev/stderr)
  [ "${actual}" = "creds" ]
  local actual=$(helm template \
    --show-only templates/snapshotagent-cronjob.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.s3CredentialsSecret=creds' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.spec.jobTemplate.spec.template.spec.containers[0].env[] | select(.name == "AWS_ACCESS_KEY_ID") | .valueFrom.secretKeyRef.name' | tee /dev/stderr)
  [ "${actual}" = "creds" ]
}

@test "snapshot/serviceaccount: disabled" {
  cd `chart_dir`
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

@test "snapshot/configmap: configuration: s3Host" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.config.s3Host=s3.us-west-1.amazonaws.com' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.S3_HOST' | tee /dev/stderr)
  [ "${actual}" = "s3.us-west-1.amazonaws.com" ]
}

@test "snapshot/configmap: configuration: s3Bucket" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.config.s3Bucket=my-bucket' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.S3_BUCKET' | tee /dev/stderr)
  [ "${actual}" = "my-bucket" ]
}

@test "snapshot/configmap: configuration: s3Uri" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.config.s3Uri=s3://my-bucket' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.S3_URI' | tee /dev/stderr)
  [ "${actual}" = "s3://my-bucket" ]
}

@test "snapshot/configmap: configuration: s3ExpireDays" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.config.s3ExpireDays=1' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.S3_EXPIRE_DAYS' | tee /dev/stderr)
  [ "${actual}" = 1 ]
}

@test "snapshot/configmap: configuration: s3cmdExtraFlag" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.config.s3cmdExtraFlag=-q' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.S3CMD_EXTRA_FLAG' | tee /dev/stderr)
  [ "${actual}" = "-q" ]
}

@test "snapshot/configmap: configuration: baoAuthPath" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'snapshotAgent.config.baoAuthPath=jwt' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.BAO_AUTH_PATH' | tee /dev/stderr)
  [ "${actual}" = "jwt" ]
}

@test "snapshot/configmap: configuration: baoRole" {
  cd `chart_dir`
  local actual=$(
    helm template \
      --show-only templates/snapshotagent-configmap.yaml \
      --set 'snapshotAgent.enabled=true' \
      --set 'snapshotAgent.config.baoRole=backup' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.data.BAO_ROLE' | tee /dev/stderr
  )
  [ "${actual}" = "backup" ]
}

@test "snapshot/configmap: configuration: baoAddr" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.BAO_ADDR' | tee /dev/stderr)
  [ "${actual}" = "http://release-name-openbao.foo.svc:8200" ]
}

@test "snapshot/configmap: configuration: externalBaoAddr" {
  cd `chart_dir`
  local actual=$(helm template \
    --show-only templates/snapshotagent-configmap.yaml \
    --set 'snapshotAgent.enabled=true' \
    --set 'global.externalBaoAddr=https://bao.example.com' \
    --namespace foo \
    . | tee /dev/stderr |
    yq -r '.data.BAO_ADDR' | tee /dev/stderr)
  [ "${actual}" = "https://bao.example.com" ]
}
