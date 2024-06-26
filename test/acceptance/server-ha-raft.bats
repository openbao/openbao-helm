#!/usr/bin/env bats

load _helpers

@test "server/ha-raft: testing deployment" {
  cd `chart_dir`

  helm install "$(name_prefix)" \
    --set='server.ha.enabled=true' \
    --set='server.ha.raft.enabled=true' .
  wait_for_running $(name_prefix)-0

  # Sealed, not initialized
  wait_for_sealed_vault $(name_prefix)-0

  local init_status=$(kubectl exec "$(name_prefix)-0" -- bao status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Replicas
  local replicas=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.replicas')
  [ "${replicas}" == "3" ]

  # Volume Mounts
  local volumeCount=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.spec.containers[0].volumeMounts | length')
  [ "${volumeCount}" == "3" ]

  # Volumes
  local volumeCount=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.spec.volumes | length')
  [ "${volumeCount}" == "2" ]

  local volume=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.spec.volumes[0].configMap.name')
  [ "${volume}" == "$(name_prefix)-config" ]

  # Service
  local service=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.clusterIP')
  [ "${service}" != "None" ]

  local service=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.type')
  [ "${service}" == "ClusterIP" ]

  local ports=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.ports | length')
  [ "${ports}" == "2" ]

  local ports=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.ports[0].port')
  [ "${ports}" == "8200" ]

  local ports=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.ports[1].port')
  [ "${ports}" == "8201" ]

  # OpenBao Init
  local init=$(kubectl exec -ti "$(name_prefix)-0" -- \
    bao operator init -format=json -n 1 -t 1)

  local token=$(echo ${init} | jq -r '.unseal_keys_b64[0]')
  [ "${token}" != "" ]

  local root=$(echo ${init} | jq -r '.root_token')
  [ "${root}" != "" ]

  kubectl exec -ti openbao-0 -- bao operator unseal ${token}
  wait_for_ready "$(name_prefix)-0"

  sleep 5

  # OpenBao Unseal
  local pods=($(kubectl get pods --selector='app.kubernetes.io/name=openbao' -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      if [[ ${pod?} != "$(name_prefix)-0" ]]
      then
          kubectl exec -ti ${pod} -- bao operator raft join http://$(name_prefix)-0.$(name_prefix)-internal:8200
          kubectl exec -ti ${pod} -- bao operator unseal ${token}
          wait_for_ready "${pod}"
      fi
  done

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-0" -- bao status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-0" -- bao status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl exec "$(name_prefix)-0" -- bao login ${root}

  local raft_status=$(kubectl exec "$(name_prefix)-0" -- bao operator raft list-peers -format=json |
    jq -r '.data.config.servers | length')
  [ "${raft_status}" == "3" ]
}

setup() {
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance
}

#cleanup
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      # If the test failed, print some debug output
      if [[ "$BATS_ERROR_STATUS" -ne 0 ]]; then
          kubectl logs -l app.kubernetes.io/name=openbao
      fi
      helm delete openbao
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
  fi
}
