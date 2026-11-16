#!/usr/bin/env bats

load _helpers

@test "snapshot-agent-jobs: default name" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.metadata.name == "review-openbao-snapshot"' >/dev/null
}

@test "snapshot-agent-jobs: default configmap" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-configmap.yaml --set snapshotAgent.enabled=true
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.metadata.name == "review-openbao-snapshot"' >/dev/null
}

@test "snapshot-agent-jobs: separate names and configmaps" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.jobs.a.config.s3Uri=s3://openbao-snapshots/a/ --set snapshotAgent.jobs.b.config.s3Uri=s3://openbao-snapshots/b/
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.metadata.name as $name | .spec.jobTemplate.spec.template.spec.containers[0].envFrom[0].configMapRef.name == $name and ($name | test("-snapshot-[ab]$"))' >/dev/null
}

@test "snapshot-agent-jobs: inherit role and override URI" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-configmap.yaml --set snapshotAgent.enabled=true --set snapshotAgent.jobs.a.config.s3Uri=s3://openbao-snapshots/a/ --set snapshotAgent.jobs.b.config.s3Uri=s3://openbao-snapshots/b/
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.data.BAO_ROLE == "snapshot" and (.data.S3_URI | test("/([ab])/$"))' >/dev/null
}

@test "snapshot-agent-jobs: clear scalar config" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-configmap.yaml --set snapshotAgent.enabled=true --set snapshotAgent.jobs.cold.config.s3ExpireDays=
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.data.S3_EXPIRE_DAYS == ""' >/dev/null
}

@test "snapshot-agent-jobs: schedule override" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set 'snapshotAgent.jobs.cold.schedule=0 2 * * *' --set snapshotAgent.jobs.cold.concurrencyPolicy=Replace
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.schedule == "0 2 * * *" and .spec.concurrencyPolicy == "Replace"' >/dev/null
}

@test "snapshot-agent-jobs: credentials override" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.s3CredentialsSecret=shared --set snapshotAgent.jobs.cold.s3CredentialsSecret=cold
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.jobTemplate.spec.template.spec.containers[0].env | map(select(.name == "AWS_ACCESS_KEY_ID"))[0].valueFrom.secretKeyRef.name == "cold"' >/dev/null
}

@test "snapshot-agent-jobs: duplicate" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set 'snapshotAgent.jobs.a.schedule=0 * * * *' --set 'snapshotAgent.jobs.b.schedule=5 * * * *'
  [ "$status" -eq 1 ]
  [[ "$output" == *'overlapping S3 paths'* ]]
}

@test "snapshot-agent-jobs: nested" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.jobs.a.config.s3Uri=s3://openbao-snapshots/a --set snapshotAgent.jobs.b.config.s3Uri=s3://openbao-snapshots/a/cold
  [ "$status" -eq 1 ]
  [[ "$output" == *'overlapping S3 paths'* ]]
}

@test "snapshot-agent-jobs: invalid name" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set 'snapshotAgent.jobs.Bad.schedule=0 * * * *'
  [ "$status" -eq 1 ]
  [[ "$output" == *'invalid DNS label'* ]]
}

@test "snapshot-agent-jobs: long name" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set 'snapshotAgent.jobs.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.schedule=0 * * * *'
  [ "$status" -eq 1 ]
  [[ "$output" == *'exceeds 52'* ]]
}

@test "snapshot-agent-jobs: bucket mismatch" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.jobs.a.config.s3Bucket=other
  [ "$status" -eq 1 ]
  [[ "$output" == *'matching s3Uri'* ]]
}

@test "snapshot-agent-jobs: unknown override" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.jobs.a.image.tag=bad
  [ "$status" -eq 1 ]
  [[ "$output" == *image* ]]
}

@test "snapshot-agent-jobs: different hosts same URI" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml --set snapshotAgent.enabled=true --set snapshotAgent.jobs.a.config.s3Host=a.example --set snapshotAgent.jobs.b.config.s3Host=b.example
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.kind == "CronJob"' >/dev/null
}

@test "snapshot-agent-jobs: two independent jobs and explicit empty replacements" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/snapshotagent-cronjob.yaml -f ../../test/unit/fixtures/snapshot-jobs.json
  [ "$status" -eq 0 ]
  echo "$output" | yq -e -s '
    length == 2 and
    (map(.metadata.name) == ["review-openbao-snapshot-a", "review-openbao-snapshot-b"]) and
    (.[0].spec.jobTemplate.spec.template.spec.containers[0] | .resources == null and (.env // [] | length == 0)) and
    (.[1].spec.jobTemplate.spec.template.spec.containers[0] | .resources.requests.cpu == "100m" and (.env | length == 2)) and
    (.[0].spec.jobTemplate.spec.template.spec.serviceAccountName == .[1].spec.jobTemplate.spec.template.spec.serviceAccountName)
  ' >/dev/null
}
