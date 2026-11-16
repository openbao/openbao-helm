#!/usr/bin/env bats

load _helpers

setup() {
  cd "$(chart_dir)"
}

@test "global-image-registry: server global override" {
  run helm template review . --show-only templates/server-statefulset.yaml --set global.imageRegistry=mirror.example/project/
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | startswith("mirror.example/project/") and (contains("//") | not)' >/dev/null
}

@test "global-image-registry: test global override" {
  run helm template review . --show-only templates/tests/server-test.yaml --set global.imageRegistry=mirror.example/project/
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.containers[0].image | startswith("mirror.example/project/") and (contains("//") | not)' >/dev/null
}

@test "global-image-registry: injector global override" {
  run helm template review . --show-only templates/injector-deployment.yaml --set global.imageRegistry=mirror.example/project/
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | startswith("mirror.example/project/") and (contains("//") | not)' >/dev/null
}

@test "global-image-registry: CSI global override" {
  run helm template review . --show-only templates/csi-daemonset.yaml --set csi.enabled=true --set global.imageRegistry=mirror.example/project/
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | startswith("mirror.example/project/") and (contains("//") | not)' >/dev/null
}

@test "global-image-registry: snapshot global override" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set global.imageRegistry=mirror.example/project/
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image | startswith("mirror.example/project/") and (contains("//") | not)' >/dev/null
}

@test "global-image-registry: injector agent override" {
  run helm template review . --show-only templates/injector-deployment.yaml --set global.imageRegistry=mirror.example/project
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].env | map(select(.name == "AGENT_INJECT_VAULT_IMAGE"))[0].value | startswith("mirror.example/project/")' >/dev/null
}

@test "global-image-registry: CSI agent override" {
  run helm template review . --show-only templates/csi-daemonset.yaml --set csi.enabled=true --set global.imageRegistry=mirror.example/project
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[1].image | startswith("mirror.example/project/")' >/dev/null
}

@test "global-image-registry: global beats component" {
  run helm template review . --show-only templates/server-statefulset.yaml --set global.imageRegistry=mirror.example --set server.image.registry=other.example
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | startswith("mirror.example/")' >/dev/null
}

@test "global-image-registry: empty server registry fallback" {
  run helm template review . --show-only templates/server-statefulset.yaml --set server.image.registry=
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.template.spec.containers[0].image | startswith("docker.io/")' >/dev/null
}

@test "global-image-registry: snapshot preserves a legacy registry with a port" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.repository=localhost:5000/a/snap --set global.imageRegistry=
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "localhost:5000/a/snap:0.4.5"' >/dev/null
}

@test "global-image-registry: snapshot replaces localhost with the global registry" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.repository=localhost/a/snap --set global.imageRegistry=mirror.example/project
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "mirror.example/project/a/snap:0.4.5"' >/dev/null
}

@test "global-image-registry: snapshot preserves an unqualified legacy repository" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.repository=my-repo --set global.imageRegistry=
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "my-repo:0.4.5"' >/dev/null
}

@test "global-image-registry: snapshot prefixes an unqualified repository" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.repository=my-repo --set global.imageRegistry=mirror.example
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "mirror.example/my-repo:0.4.5"' >/dev/null
}

@test "global-image-registry: snapshot replaces a legacy registry host" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.repository=harbor.example/a/snap --set global.imageRegistry=mirror.example
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "mirror.example/a/snap:0.4.5"' >/dev/null
}

@test "global-image-registry: snapshot per image override" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.image.registry=mirror.example
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "mirror.example/openbao/openbao-snapshot-agent:0.4.5"' >/dev/null
}

@test "global-image-registry: global beats snapshot registry and repository host" {
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml \
    --set snapshotAgent.enabled=true \
    --set snapshotAgent.image.repository=legacy.example/project/snapshot \
    --set snapshotAgent.image.registry=component.example \
    --set global.imageRegistry=global.example/mirror
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].image == "global.example/mirror/project/snapshot:0.4.5"' >/dev/null
}
