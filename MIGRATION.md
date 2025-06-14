# Migration Guide: HashiCorp Vault to OpenBao Helm Chart

This guide helps you migrate from the HashiCorp Vault Helm chart to the OpenBao Helm chart.

## Overview

OpenBao is a community-driven fork of HashiCorp Vault, created after HashiCorp's license change. The OpenBao Helm chart maintains compatibility with most Vault configurations while using OpenBao binaries and images.

## Key Differences

### Binary and Image Changes

| Component | Vault | OpenBao |
|-----------|--------|---------|
| **CLI Binary** | `vault` | `bao` |
| **Server Image** | `hashicorp/vault` | `openbao/openbao` |
| **K8s Injector Image** | `hashicorp/vault-k8s` | `hashicorp/vault-k8s`* |
| **CSI Provider Image** | `hashicorp/vault-csi-provider` | `hashicorp/vault-csi-provider`* |

*Note: Injector and CSI provider still use HashiCorp images as they're client-side tools.

### Configuration Paths

| Type | Vault | OpenBao |
|------|--------|---------|
| **Config Directory** | `/vault/config` | `/openbao/config` |
| **Data Directory** | `/vault/data` | `/openbao/data` |
| **Audit Directory** | `/vault/audit` | `/openbao/audit` |
| **Annotations Prefix** | `vault.hashicorp.com/` | `openbao.openbao.org/` |

## Pre-Migration Checklist

- [ ] **Backup your data** - Create snapshots/backups of your Vault data
- [ ] **Document your configuration** - Export policies, auth methods, secrets engines
- [ ] **Test in non-production** - Always test migration in a separate environment
- [ ] **Plan downtime** - Some migration strategies require downtime
- [ ] **Update client applications** - Prepare to update Vault clients to use `bao` CLI

## Migration Strategies

### Strategy 1: Fresh Installation (Recommended for New Deployments)

Best for:
- New deployments
- Development/test environments
- When you can recreate configuration

Steps:
1. Install OpenBao Helm chart
2. Initialize and unseal OpenBao
3. Recreate policies, auth methods, and secrets engines
4. Update applications to use OpenBao

### Strategy 2: Data Migration (For Existing Data)

Best for:
- Production environments with existing data
- When you need to preserve secrets and configuration

Steps:
1. Create backup of Vault data
2. Deploy OpenBao in parallel
3. Restore data to OpenBao
4. Switch traffic to OpenBao
5. Decommission Vault

### Strategy 3: Gradual Migration

Best for:
- Large deployments
- Zero-downtime requirements
- Complex configurations

Steps:
1. Deploy OpenBao alongside Vault
2. Configure replication or synchronization
3. Gradually move workloads to OpenBao
4. Decommission Vault after full migration

## Step-by-Step Migration Guide

### Step 1: Export Vault Configuration

```bash
# Export policies
vault policy list | while read policy; do
  vault policy read $policy > policies/${policy}.hcl
done

# Export auth methods
vault auth list -format=json > auth-methods.json

# Export secrets engines  
vault secrets list -format=json > secrets-engines.json

# Create Raft snapshot (if using Raft)
vault operator raft snapshot save vault-backup.snap
```

### Step 2: Update Helm Values

Transform your `values.yaml`:

```yaml
# Old (Vault)
global:
  image:
    repository: "hashicorp/vault"
    tag: "1.15.0"

server:
  image:
    repository: "hashicorp/vault"
    tag: "1.15.0"

# New (OpenBao)
global:
  image:
    repository: "openbao/openbao"
    tag: "2.2.2"

server:
  image:
    repository: "openbao/openbao"
    tag: "2.2.2"
```

### Step 3: Update Annotations

For pods using agent injection:

```yaml
# Old (Vault)
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "myapp"
  vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp"

# New (OpenBao)  
annotations:
  openbao.openbao.org/agent-inject: "true"
  openbao.openbao.org/role: "myapp"
  openbao.openbao.org/agent-inject-secret-config: "secret/data/myapp"
```

### Step 4: Deploy OpenBao

```bash
# Add OpenBao Helm repository
helm repo add openbao https://openbao.github.io/openbao-helm

# Install OpenBao with your values
helm install openbao openbao/openbao -f values-openbao.yaml
```

### Step 5: Restore Data

For Raft storage:
```bash
# Initialize OpenBao
bao operator init

# Restore from snapshot
bao operator raft snapshot restore vault-backup.snap
```

For Consul storage:
```bash
# If using same Consul cluster, data is already available
# Just need to unseal OpenBao
bao operator unseal
```

### Step 6: Update Applications

Update your applications:

```bash
# Old
export VAULT_ADDR=https://vault.example.com:8200
vault login -method=kubernetes

# New
export VAULT_ADDR=https://openbao.example.com:8200
bao login -method=kubernetes
```

Update CI/CD pipelines:
```yaml
# Old
- name: Login to Vault
  run: vault login -method=aws

# New  
- name: Login to OpenBao
  run: bao login -method=aws
```

## Configuration Mappings

### Storage Configuration

```hcl
# Vault configuration works unchanged in OpenBao
storage "raft" {
  path = "/openbao/data"  # Update path
  node_id = "node1"
}

storage "consul" {
  address = "consul:8500"
  path = "openbao/"  # Update path prefix
}
```

### Listener Configuration

```hcl
# Configuration remains the same
listener "tcp" {
  address = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable = 1
}
```

### Seal Configuration

```hcl
# Auto-unseal configuration unchanged
seal "awskms" {
  region = "us-east-1"
  kms_key_id = "12345678-1234-1234-1234-123456789012"
}
```

## Common Issues and Solutions

### Issue: Pods not getting injected secrets

**Solution**: Update annotations from `vault.hashicorp.com/` to `openbao.openbao.org/`

### Issue: CLI commands failing

**Solution**: Replace `vault` with `bao` in all commands

### Issue: Path not found errors

**Solution**: Update paths from `/vault/` to `/openbao/`

### Issue: Authentication failures

**Solution**: Recreate Kubernetes auth configuration with OpenBao endpoints

## Rollback Plan

If you need to rollback:

1. Keep Vault deployment running during migration
2. Document all changes made
3. Test rollback procedure in advance
4. Have backups ready

Rollback steps:
```bash
# Switch DNS/load balancer back to Vault
# Update application configurations
# Restore from Vault backup if needed
```

## Post-Migration Checklist

- [ ] All applications successfully authenticating
- [ ] Secrets accessible as expected
- [ ] Monitoring and alerting working
- [ ] Backup procedures updated
- [ ] Documentation updated
- [ ] Team trained on `bao` CLI
- [ ] Old Vault instances decommissioned

## Additional Resources

- [OpenBao Documentation](https://openbao.org/docs/)
- [OpenBao vs Vault Comparison](https://openbao.org/docs/concepts/openbao-vs-vault/)
- [OpenBao Community Chat](https://chat.lfx.linuxfoundation.org)

## Support

If you encounter issues during migration:

1. Check the [OpenBao GitHub Issues](https://github.com/openbao/openbao/issues)
2. Join the [OpenBao Community Chat](https://chat.lfx.linuxfoundation.org)
3. Review the [troubleshooting guide](./README.md#troubleshooting)