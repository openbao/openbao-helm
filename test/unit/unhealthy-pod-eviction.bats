#!/usr/bin/env bats

load _helpers

@test "unhealthy-pod-eviction: unset" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-disruptionbudget.yaml --set server.ha.enabled=true
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.unhealthyPodEvictionPolicy == null' >/dev/null
}

@test "unhealthy-pod-eviction: IfHealthyBudget" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-disruptionbudget.yaml --set server.ha.enabled=true --set server.ha.disruptionBudget.unhealthyPodEvictionPolicy=IfHealthyBudget
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.unhealthyPodEvictionPolicy == "IfHealthyBudget" and .spec.maxUnavailable == 1' >/dev/null
}

@test "unhealthy-pod-eviction: AlwaysAllow" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-disruptionbudget.yaml --set server.ha.enabled=true --set server.ha.disruptionBudget.unhealthyPodEvictionPolicy=AlwaysAllow
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.unhealthyPodEvictionPolicy == "AlwaysAllow" and .spec.maxUnavailable == 1' >/dev/null
}

@test "unhealthy-pod-eviction: single healthy replica budget" {
  cd "$(chart_dir)"
  run helm template review . --show-only templates/server-disruptionbudget.yaml --set server.ha.enabled=true --set server.ha.replicas=1 --set server.ha.disruptionBudget.unhealthyPodEvictionPolicy=AlwaysAllow
  [ "$status" -eq 0 ]
  echo "$output" | yq -e '.spec.maxUnavailable == 0' >/dev/null
}

@test "unhealthy-pod-eviction: invalid policy" {
  cd "$(chart_dir)"
  run helm template review . --set server.ha.disruptionBudget.unhealthyPodEvictionPolicy=bad
  [ "$status" -eq 1 ]
  [[ "$output" == *unhealthyPodEvictionPolicy* ]]
}
