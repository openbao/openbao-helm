#!/usr/bin/env bats

load _helpers

@test "snapshotAgent: testing snapshot" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  # create s3 bucket for testing
  kubectl run -n localstack aws-cli --image=amazon/aws-cli --restart=Never \
    --env="AWS_ACCESS_KEY_ID=test" --env="AWS_SECRET_ACCESS_KEY=test" \
    --env="AWS_DEFAULT_REGION=us-east-1" --env="AWS_ENDPOINT_URL=http://localstack:4566" \
    -- s3 mb s3://openbao-snapshots
  kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/aws-cli -n localstack --timeout=60s || true
  kubectl delete po aws-cli -n localstack

  # create secret to be used by cronjob
  kubectl create secret generic s3-creds --from-literal=AWS_ACCESS_KEY_ID=test --from-literal=AWS_SECRET_ACCESS_KEY=test

  # initialize openbao first
  initialize

  # Extract root token
  local root_token=$(cat root.json | jq -r '.root_token')
  [ "${root_token}" != "" ]

  echo "ROOT: $root_token"

  # enable kv v2 secrets engine
  kubectl exec -ti "$(name_prefix)-0" -- \
    sh -c "BAO_TOKEN=${root_token} bao secrets enable -path=secret -version=2 kv"

  # Create sample secret
  kubectl exec -ti "$(name_prefix)-0" -- \
    sh -c "BAO_TOKEN=${root_token} bao kv put secret/data/acceptance foo=bar"

  # configure kubernetes auth & role
  # enable kubernetes auth
  kubectl exec -ti "$(name_prefix)-0" -- \
    sh -c "BAO_TOKEN=${root_token} bao auth enable kubernetes"

  # write kubernetes auth configuration
  kubectl exec -ti "$(name_prefix)-0" -- \
    sh -c "BAO_TOKEN=${root_token} bao write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

  # create policy for snapshotting
  local policy=$(
    cat <<EOF
path "sys/storage/raft/snapshot" {
  capabilities = ["read"]
}
EOF
  )
  echo "${policy}" | kubectl \
    exec -ti "$(name_prefix)-0" -- \
    sh -c "BAO_TOKEN=${root_token} bao policy write snapshot -"

  # write role for snapshot agent
  kubectl exec -ti "$(name_prefix)-0" -- \
    sh -c "BAO_TOKEN=${root_token} bao write auth/kubernetes/role/snapshot \
  bound_service_account_names=$(name_prefix)-snapshot \
  bound_service_account_namespaces=acceptance policies=snapshot \
  ttl=1h"

  # redeploy with snapshotAgent enabled
  helm upgrade --install "$(name_prefix)" . --set injector.enabled=false \
    --set server.ha.enabled=true \
    --set server.ha.replicas=1 \
    --set server.ha.raft.enabled=true \
    --set snapshotAgent.enabled=true \
    --set snapshotAgent.config.s3Bucket=openbao-snapshots \
    --set snapshotAgent.config.s3Uri=s3://openbao-snapshots \
    --set snapshotAgent.config.s3Host=localstack.localstack.svc:4566 \
    --set snapshotAgent.config.s3cmdExtraFlag=--no-check-certificate \
    --set snapshotAgent.s3CredentialsSecret=s3-creds \
    --set snapshotAgent.config.baoAddr=http://$(name_prefix):8200

  # run the cronjob, and check if it completed succesfully
  kubectl create job acceptance --from=cronjob/$(name_prefix)-snapshot
  kubectl wait --for=condition=complete job/acceptance --timeout=60s || true

  # check for job status == completed
  local cronjob_status=$(kubectl get job acceptance -o json | jq -r '.status.succeeded')
  [ "${cronjob_status}" == "1" ]

  # check for s3 bucket containing snapshot
  kubectl run -n localstack aws-cli --image=amazon/aws-cli --restart=Never \
    --env="AWS_ACCESS_KEY_ID=test" --env="AWS_SECRET_ACCESS_KEY=test" \
    --env="AWS_DEFAULT_REGION=us-east-1" --env="AWS_ENDPOINT_URL=http://localstack:4566" \
    -- s3 ls s3://openbao-snapshots
  kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/aws-cli -n localstack --timeout=60s || true

  local s3_ls=$(kubectl logs -n localstack aws-cli | grep -c snapshot)
  [ "${s3_ls}" -gt 0 ]

  # teardown everything and delete pvc
  kubectl delete po aws-cli -n localstack

  #teardown

  # backup old root_token
  #mv root.json snapshot-root.json

  # re-initialize
  #init

  # restore from backup

}

# initialize
initialize() {
  # install openbao
  helm install "$(name_prefix)" . --set injector.enabled=false \
    --set server.ha.enabled=true \
    --set server.ha.replicas=1 \
    --set server.ha.raft.enabled=true
  wait_for_running $(name_prefix)-0

  # Sealed, not initialized
  wait_for_sealed_vault $(name_prefix)-0

  local init_status=$(kubectl exec "$(name_prefix)-0" -- bao status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # OpenBao Init
  local init=$(kubectl exec -ti "$(name_prefix)-0" -- \
    bao operator init -format=json -n 1 -t 1 | tee root.json)
  [ "${init}" != "" ]

  # Extract unseal token
  local unseal_token=$(cat root.json | jq -r '.unseal_keys_b64[0]')
  [ "${unseal_token}" != "" ]

  # OpenBao Unseal
  local pods=($(kubectl get pods --selector='app.kubernetes.io/name=openbao' -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"; do
    kubectl exec -ti ${pod} -- bao operator unseal ${unseal_token}
  done

  wait_for_ready "$(name_prefix)-0"

  # Unsealed, initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-0" -- bao status -format=json |
    jq -r '.sealed')
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-0" -- bao status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]
}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]; then
    echo "helm/pvc teardown"
    helm delete openbao
    kubectl delete --all pvc
    kubectl delete namespace acceptance --ignore-not-found=true
    rm root.json
  fi
}
