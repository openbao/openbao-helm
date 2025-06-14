# OpenBao CSI Provider Example

This example demonstrates how to use the OpenBao CSI Provider to mount secrets as files in Kubernetes pods.

## Overview

The CSI (Container Storage Interface) provider allows you to:
- Mount OpenBao secrets as files in pods
- Sync secrets to Kubernetes secrets (optional)
- Avoid sidecar containers
- Use native Kubernetes volume mounts

## Prerequisites

- Kubernetes cluster with CSI support
- OpenBao deployed and configured
- Secrets Store CSI Driver installed
- OpenBao CSI Provider enabled

### Install Secrets Store CSI Driver

```bash
# Add the Secrets Store CSI Driver helm repo
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

# Install the driver
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true
```

## Setup Instructions

### 1. Enable CSI Provider in OpenBao

Ensure your OpenBao deployment has CSI enabled:

```bash
helm upgrade openbao openbao/openbao --set csi.enabled=true
```

### 2. Configure OpenBao

```bash
# Create a policy for the application
bao policy write webapp policy.hcl

# Enable Kubernetes auth
bao auth enable kubernetes

# Configure Kubernetes auth
bao write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# Create a role
bao write auth/kubernetes/role/webapp \
    bound_service_account_names=webapp \
    bound_service_account_namespaces=default \
    policies=webapp \
    ttl=20m
```

### 3. Create Secrets in OpenBao

```bash
# Enable KV secrets engine
bao secrets enable -path=secret kv-v2

# Create application secrets
bao kv put secret/webapp/database \
    username="dbuser" \
    password="dbpass123" \
    host="postgres.example.com" \
    port="5432"

bao kv put secret/webapp/api \
    key="abc123" \
    secret="xyz789" \
    endpoint="https://api.example.com"
```

### 4. Deploy SecretProviderClass

The SecretProviderClass defines how to fetch secrets from OpenBao:

```bash
kubectl apply -f secretproviderclass.yaml
```

### 5. Deploy Application

Deploy an application that uses the CSI volume:

```bash
kubectl apply -f deployment.yaml
```

### 6. Verify Secrets

```bash
# Check that secrets are mounted
kubectl exec deployment/webapp -- ls -la /mnt/secrets-store

# View secret contents
kubectl exec deployment/webapp -- cat /mnt/secrets-store/database-username
kubectl exec deployment/webapp -- cat /mnt/secrets-store/database-password

# If using secret sync, check Kubernetes secret
kubectl get secret webapp-db-secret -o yaml
```

## How It Works

1. **Pod Creation**: When a pod is created with CSI volume
2. **Driver Call**: CSI driver calls OpenBao CSI provider
3. **Authentication**: Provider authenticates using pod's service account
4. **Secret Fetch**: Secrets are fetched from OpenBao
5. **Mount**: Secrets are written to tmpfs and mounted in pod
6. **Sync (Optional)**: Secrets can be synced to Kubernetes secrets

## Configuration Options

### Basic Secret Mount

```yaml
# Mounts all keys from a KV path
- objectName: "database-config"
  objectType: "kv"
  objectPath: "secret/data/webapp/database"
  objectVersion: ""  # Latest version
```

### Individual Key Selection

```yaml
# Mount specific keys only
- objectName: "db-username"
  objectType: "kv"
  objectPath: "secret/data/webapp/database"
  objectVersion: ""
  objectKey: "username"  # Only mount this key
```

### PKI Certificate

```yaml
# Generate and mount certificates
- objectName: "webapp-cert"
  objectType: "pki"
  objectPath: "pki/issue/webapp"
  objectVersion: ""
  objectData:
    common_name: "webapp.example.com"
    ttl: "720h"
```

### Transit Encryption Key

```yaml
# Mount transit key for encryption operations
- objectName: "encryption-key"
  objectType: "transit"
  objectPath: "transit/keys/webapp"
  objectVersion: ""
```

## Secret Rotation

The CSI driver supports automatic rotation:

```yaml
# In SecretProviderClass
spec:
  parameters:
    roleName: "webapp"
    vaultAddress: "http://openbao:8200"
    vaultSkipTLSVerify: "false"
    # Enable rotation
    objects: |
      - objectName: "database-config"
        objectType: "kv"
        objectPath: "secret/data/webapp/database"
        objectVersion: ""
    # Rotation is checked based on pod events
```

## Kubernetes Secret Sync

To sync OpenBao secrets to Kubernetes secrets:

```yaml
# In SecretProviderClass
spec:
  secretObjects:
  - secretName: webapp-db-secret
    type: Opaque
    data:
    - objectName: database-username
      key: username
    - objectName: database-password
      key: password
```

## Advanced Features

### File Permissions

```yaml
# Set specific file permissions
volumes:
- name: secrets-store
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: "webapp-secrets"
      # Custom permissions
      file-permission: "0400"
      uid: "1000"
      gid: "1000"
```

### Multiple Secret Sources

```yaml
# Mount from multiple paths
parameters:
  objects: |
    - objectName: "database"
      objectType: "kv"
      objectPath: "secret/data/webapp/database"
    - objectName: "api-keys"
      objectType: "kv"
      objectPath: "secret/data/webapp/api"
    - objectName: "tls-cert"
      objectType: "pki"
      objectPath: "pki/issue/webapp"
```

### Environment Variables

While CSI mounts files, you can load them as env vars:

```yaml
# In your container
command: ["/bin/sh"]
args:
  - -c
  - |
    export DB_USER=$(cat /mnt/secrets-store/database-username)
    export DB_PASS=$(cat /mnt/secrets-store/database-password)
    exec /app/start.sh
```

## Troubleshooting

### Secrets Not Mounting

1. Check CSI driver pods:
```bash
kubectl get pods -n kube-system | grep csi
kubectl logs -n kube-system csi-secrets-store-*
```

2. Check provider logs:
```bash
kubectl logs -l app.kubernetes.io/name=openbao-csi-provider
```

3. Verify SecretProviderClass:
```bash
kubectl describe secretproviderclass webapp-secrets
```

### Authentication Failures

1. Verify service account:
```bash
kubectl get sa webapp -o yaml
```

2. Check OpenBao role:
```bash
bao read auth/kubernetes/role/webapp
```

3. Test authentication:
```bash
kubectl run test --rm -it --restart=Never \
  --serviceaccount=webapp \
  --image=curlimages/curl -- sh
# Inside pod:
JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -X POST http://openbao:8200/v1/auth/kubernetes/login \
  -d "{\"jwt\": \"$JWT\", \"role\": \"webapp\"}"
```

### Performance Considerations

- CSI mounts happen at pod startup
- Large secrets may slow pod initialization
- Consider using pagination for many secrets
- Monitor CSI driver resource usage

## Security Best Practices

1. **Least Privilege**: Only mount required secrets
2. **Service Account Binding**: Bind to specific service accounts
3. **Namespace Isolation**: Restrict to specific namespaces
4. **Secret Rotation**: Enable automatic rotation
5. **Audit Logging**: Monitor secret access in OpenBao

## Cleanup

```bash
kubectl delete -f deployment.yaml
kubectl delete -f secretproviderclass.yaml
kubectl delete sa webapp
bao delete auth/kubernetes/role/webapp
bao policy delete webapp
```