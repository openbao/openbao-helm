#!/usr/bin/env bats

load _helpers

@test "server: API server accepts and preserves unhealthyPodEvictionPolicy" {
  cd "$(chart_dir)"
  local manifest="$BATS_TEST_TMPDIR/pdb.yaml"
  helm template eviction . --show-only templates/server-disruptionbudget.yaml \
    --set server.ha.enabled=true \
    --set server.ha.disruptionBudget.unhealthyPodEvictionPolicy=AlwaysAllow > "$manifest"
  run kubectl apply --dry-run=server -f "$manifest" -o jsonpath='{.spec.unhealthyPodEvictionPolicy}'
  [ "$status" -eq 0 ]
  [ "$output" = "AlwaysAllow" ]
}
