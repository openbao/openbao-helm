# OpenBao Agent Injection Example

This example demonstrates how to use OpenBao Agent Injector to automatically inject secrets into your Kubernetes pods.

## Overview

The OpenBao Agent Injector uses a Kubernetes Mutating Webhook to intercept pod creation and automatically inject:
- An init container to authenticate and fetch secrets
- A sidecar container to keep secrets updated
- Shared memory volumes for secret storage

## Prerequisites

- OpenBao deployed with injector enabled
- OpenBao initialized and unsealed
- kubectl configured

## Setup Instructions

### 1. Configure Kubernetes Authentication

```bash
# Enable Kubernetes auth method
bao auth enable kubernetes

# Configure Kubernetes auth
bao write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    issuer="https://kubernetes.default.svc.cluster.local"
```

### 2. Create a Test Secret

```bash
# Create a KV secrets engine
bao secrets enable -path=secret kv-v2

# Create a test secret
bao kv put secret/webapp/config \
    username="appuser" \
    password="suP3rsecr3t" \
    api_key="abc123def456" \
    database_url="postgresql://db.example.com:5432/myapp"
```

### 3. Create OpenBao Policy

```bash
# Apply the policy
bao policy write webapp policy.hcl

# Create Kubernetes auth role
bao write auth/kubernetes/role/webapp \
    bound_service_account_names=webapp \
    bound_service_account_namespaces=default \
    policies=webapp \
    ttl=24h
```

### 4. Deploy Application with Injection

```bash
# Create service account
kubectl apply -f service-account.yaml

# Deploy the example application
kubectl apply -f deployment.yaml
```

### 5. Verify Secret Injection

```bash
# Check that the pod has injected containers
kubectl get pod -l app=webapp -o jsonpath='{.items[0].spec.containers[*].name}'

# View the injected secrets
kubectl exec deployment/webapp -- cat /vault/secrets/config.txt

# Check agent logs
kubectl logs deployment/webapp -c vault-agent
```

## How It Works

1. **Pod Creation**: When you create a pod with injection annotations
2. **Webhook Intercept**: The mutating webhook intercepts the pod spec
3. **Container Injection**: Init and sidecar containers are added
4. **Authentication**: Init container authenticates using the service account
5. **Secret Retrieval**: Agent fetches secrets and writes to shared volume
6. **Template Rendering**: Secrets are rendered using specified templates
7. **Continuous Updates**: Sidecar keeps secrets updated

## Annotation Reference

### Basic Annotations

```yaml
openbao.openbao.org/agent-inject: "true"
openbao.openbao.org/role: "webapp"
openbao.openbao.org/agent-inject-secret-config: "secret/data/webapp/config"
```

### Advanced Annotations

```yaml
# Custom template
openbao.openbao.org/agent-inject-template-config: |
  {{ with secret "secret/data/webapp/config" -}}
  export DB_USERNAME="{{ .Data.data.username }}"
  export DB_PASSWORD="{{ .Data.data.password }}"
  {{- end }}

# File permissions
openbao.openbao.org/agent-inject-perms-config: "0400"

# Run as init container only (no sidecar)
openbao.openbao.org/agent-pre-populate-only: "true"

# Custom mount path
openbao.openbao.org/agent-inject-mount-config: "/app/secrets"

# Agent resources
openbao.openbao.org/agent-limits-cpu: "250m"
openbao.openbao.org/agent-limits-mem: "128Mi"
```

## Multiple Secrets Example

```yaml
annotations:
  openbao.openbao.org/agent-inject: "true"
  openbao.openbao.org/role: "webapp"
  
  # Database credentials
  openbao.openbao.org/agent-inject-secret-db: "database/creds/readonly"
  openbao.openbao.org/agent-inject-template-db: |
    {{ with secret "database/creds/readonly" -}}
    export DB_USER="{{ .Data.username }}"
    export DB_PASS="{{ .Data.password }}"
    {{- end }}
  
  # API keys
  openbao.openbao.org/agent-inject-secret-api: "secret/data/webapp/api"
  openbao.openbao.org/agent-inject-template-api: |
    {{ with secret "secret/data/webapp/api" -}}
    API_KEY={{ .Data.data.key }}
    API_SECRET={{ .Data.data.secret }}
    {{- end }}
```

## Troubleshooting

### Injection Not Working

1. Check webhook is running:
```bash
kubectl get pods -l app.kubernetes.io/name=openbao-agent-injector
```

2. Check webhook configuration:
```bash
kubectl get mutatingwebhookconfigurations openbao-agent-injector-cfg -o yaml
```

3. Check service account permissions:
```bash
kubectl auth can-i create pods --as=system:serviceaccount:default:webapp
```

### Authentication Failures

1. Verify Kubernetes auth is configured:
```bash
bao read auth/kubernetes/config
```

2. Check role configuration:
```bash
bao read auth/kubernetes/role/webapp
```

3. View agent logs:
```bash
kubectl logs <pod-name> -c vault-agent-init
```

### Common Issues

- **No injection**: Ensure annotations are correct and webhook is running
- **Permission denied**: Check OpenBao policy and Kubernetes auth role
- **Template errors**: Validate template syntax
- **Secret not found**: Verify secret path and permissions

## Security Best Practices

1. **Least Privilege**: Grant minimum required permissions
2. **Short TTLs**: Use short-lived tokens
3. **Namespace Isolation**: Bind roles to specific namespaces
4. **Audit Logging**: Enable OpenBao audit logs
5. **Secret Rotation**: Implement regular rotation

## Cleanup

```bash
kubectl delete -f deployment.yaml
kubectl delete -f service-account.yaml
bao delete auth/kubernetes/role/webapp
bao policy delete webapp
```