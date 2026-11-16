#!/usr/bin/env bats

load _helpers

@test "extra-volume-claims: standalone" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.volumeClaimTemplates | map(.metadata.name) == ["data","audit-siem","cache"]' >/dev/null
}

@test "extra-volume-claims: extras only" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set server.dataStorage.enabled=false -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.volumeClaimTemplates | length == 2' >/dev/null
}

@test "extra-volume-claims: audit order" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set server.auditStorage.enabled=true -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.volumeClaimTemplates | map(.metadata.name) == ["data","audit","audit-siem","cache"]' >/dev/null
}

@test "extra-volume-claims: raft" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set server.ha.enabled=true --set server.ha.raft.enabled=true -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.volumeClaimTemplates | map(.metadata.name) == ["data","audit-siem","cache"]' >/dev/null
}

@test "extra-volume-claims: non raft" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set server.ha.enabled=true -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.volumeClaimTemplates | map(.metadata.name) == ["audit-siem","cache"]' >/dev/null
}

@test "extra-volume-claims: dev" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set server.dev.enabled=true -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.volumeClaimTemplates == null' >/dev/null
}

@test "extra-volume-claims: preserves metadata and spec" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.volumeClaimTemplates[1] | .apiVersion == "v1" and .kind == "PersistentVolumeClaim" and .metadata.labels.purpose == "siem" and .spec.storageClassName == "standard" and .spec.resources.requests.storage == "1Gi"' >/dev/null
}

@test "extra-volume-claims: retention" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set server.persistentVolumeClaimRetentionPolicy.whenDeleted=Retain -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.persistentVolumeClaimRetentionPolicy.whenDeleted == "Retain"' >/dev/null
}

@test "extra-volume-claims: test pod excludes extra claims" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/tests/server-test.yaml -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.containers[0].volumeMounts | map(.name) == ["plugins"]' >/dev/null
}

@test "extra-volume-claims: test pod excludes all extra claim mounts" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/tests/server-test.yaml \
    -f ../../test/unit/fixtures/extra-volume-claims.json \
    --set 'server.volumeMounts[1].name=cache'
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.containers[0].volumeMounts == null' >/dev/null
}

@test "extra-volume-claims: rejects name data" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set 'server.extraVolumeClaimTemplates[0].metadata.name=data' -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 1 ]
  [[ "$output" == *'duplicate or reserved name'* ]]
}

@test "extra-volume-claims: rejects name audit" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set 'server.extraVolumeClaimTemplates[0].metadata.name=audit' -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 1 ]
  [[ "$output" == *'duplicate or reserved name'* ]]
}

@test "extra-volume-claims: rejects name cache" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-statefulset.yaml --set 'server.extraVolumeClaimTemplates[0].metadata.name=cache' -f ../../test/unit/fixtures/extra-volume-claims.json
  [ "$status" -eq 1 ]
  [[ "$output" == *'duplicate or reserved name'* ]]
}

@test "extra-volume-claims: requires list" {
  cd "$(chart_dir)"
  run helm template review . --set server.extraVolumeClaimTemplates=bad
  [ "$status" -eq 1 ]
  [[ "$output" == *extraVolumeClaimTemplates* ]]
}
