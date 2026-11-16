#!/usr/bin/env bats

load _helpers

setup() {
  kubectl create namespace extra-claims
}

teardown() {
  helm uninstall extra-claims -n extra-claims || true
  kubectl delete namespace extra-claims --wait=false
}

@test "server: extra claims are bound per replica and excluded from helm test" {
  cd "$(chart_dir)"
  helm install extra-claims . -n extra-claims \
    --set injector.enabled=false \
    --set server.ha.enabled=true --set server.ha.raft.enabled=true \
    --set server.ha.replicas=3 --set server.podManagementPolicy=Parallel \
    --set server.affinity= \
    --set server.extraVolumeClaimTemplates[0].metadata.name=audit-siem \
    --set server.extraVolumeClaimTemplates[0].spec.accessModes[0]=ReadWriteOnce \
    --set server.extraVolumeClaimTemplates[0].spec.resources.requests.storage=1Gi \
    --set server.volumeMounts[0].name=audit-siem \
    --set server.volumeMounts[0].mountPath=/openbao/siem
  for ordinal in 0 1 2; do
    for attempt in $(seq 60); do
      kubectl get -n extra-claims pod/extra-claims-openbao-$ordinal >/dev/null 2>&1 && break
      sleep 2
    done
    kubectl wait -n extra-claims --for=jsonpath='{.status.phase}'=Running \
      pod/extra-claims-openbao-$ordinal --timeout=180s
    kubectl wait -n extra-claims --for=jsonpath='{.status.phase}'=Bound \
      pvc/audit-siem-extra-claims-openbao-$ordinal --timeout=60s
    kubectl exec -n extra-claims extra-claims-openbao-$ordinal -- \
      sh -ec 'test -d /openbao/siem; touch /openbao/siem/acceptance-check'
  done
  helm test extra-claims -n extra-claims --timeout=120s
}
