#!/usr/bin/env bats

load _helpers

@test "servicemonitor-relabelings: defaults" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/prometheus-servicemonitor.yaml --set serverTelemetry.serviceMonitor.enabled=true
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.endpoints[0] | .relabelings == null and .metricRelabelings == null' >/dev/null
}

@test "servicemonitor-relabelings: target only" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/prometheus-servicemonitor.yaml --set serverTelemetry.serviceMonitor.enabled=true --set 'serverTelemetry.serviceMonitor.relabelings[0].targetLabel=node_id'
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.endpoints[0] | .relabelings[0].targetLabel == "node_id" and .metricRelabelings == null' >/dev/null
}

@test "servicemonitor-relabelings: metric only" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/prometheus-servicemonitor.yaml --set serverTelemetry.serviceMonitor.enabled=true --set 'serverTelemetry.serviceMonitor.metricRelabelings[0].action=labeldrop'
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.endpoints[0] | .metricRelabelings[0].action == "labeldrop" and .relabelings == null' >/dev/null
}

@test "servicemonitor-relabelings: both" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/prometheus-servicemonitor.yaml --set serverTelemetry.serviceMonitor.enabled=true --set 'serverTelemetry.serviceMonitor.relabelings[0].targetLabel=node_id' --set 'serverTelemetry.serviceMonitor.metricRelabelings[0].action=labeldrop'
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.endpoints[0] | .relabelings[0].targetLabel == "node_id" and .metricRelabelings[0].action == "labeldrop" and .tlsConfig.insecureSkipVerify == true' >/dev/null
}

@test "servicemonitor-relabelings: global enable" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/prometheus-servicemonitor.yaml --set global.serverTelemetry.prometheusOperator=true --set 'serverTelemetry.serviceMonitor.relabelings[0].targetLabel=node_id'
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.endpoints[0].relabelings[0].targetLabel == "node_id"' >/dev/null
}

@test "servicemonitor-relabelings: HA selector kept" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/prometheus-servicemonitor.yaml --set serverTelemetry.serviceMonitor.enabled=true --set server.ha.enabled=true --set 'serverTelemetry.serviceMonitor.relabelings[0].targetLabel=node_id'
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.selector.matchLabels["openbao-active"] == "true"' >/dev/null
}
