# Standalone OpenBao with TLS

This example demonstrates how to deploy OpenBao in standalone mode with TLS enabled for production use.

## Prerequisites

- Kubernetes cluster with cert-manager installed
- kubectl configured to access your cluster
- Helm 3.x installed

## Setup Instructions

### 1. Install cert-manager (if not already installed)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### 2. Create TLS Certificate

Apply the certificate configuration:

```bash
kubectl apply -f certificate.yaml
```

### 3. Deploy OpenBao

Install OpenBao with TLS configuration:

```bash
helm install openbao openbao/openbao -f values.yaml
```

### 4. Initialize OpenBao

```bash
# Wait for pod to be ready
kubectl wait --for=condition=ready pod/openbao-0 --timeout=300s

# Initialize OpenBao
kubectl exec openbao-0 -- bao operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > init-keys.json

# Save the root token and unseal keys securely!
```

### 5. Unseal OpenBao

```bash
# Unseal with 3 of the 5 keys
kubectl exec openbao-0 -- bao operator unseal <unseal-key-1>
kubectl exec openbao-0 -- bao operator unseal <unseal-key-2>
kubectl exec openbao-0 -- bao operator unseal <unseal-key-3>
```

### 6. Access OpenBao

```bash
# Port forward to access OpenBao
kubectl port-forward svc/openbao 8200:8200

# Set OpenBao address and login
export VAULT_ADDR=https://localhost:8200
export VAULT_SKIP_VERIFY=true  # Only for self-signed certs

bao login <root-token>
```

## Production Considerations

1. **Certificate Management**: Use a proper CA for production certificates
2. **Backup Strategy**: Implement regular backups of the file storage
3. **Monitoring**: Enable metrics and configure alerts
4. **Access Control**: Configure proper RBAC and authentication methods
5. **Network Policies**: Implement network segmentation

## Cleanup

```bash
helm uninstall openbao
kubectl delete -f certificate.yaml
```