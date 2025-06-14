# Upgrading Guide

This guide covers upgrading the OpenBao Helm chart across different versions.

## General Upgrade Process

### Pre-Upgrade Checklist

- [ ] Review the [CHANGELOG](./CHANGELOG.md) for breaking changes
- [ ] Backup your OpenBao data
- [ ] Test upgrade in non-production environment first
- [ ] Have rollback plan ready
- [ ] Notify team of maintenance window

### Standard Upgrade Steps

1. **Update Helm Repository**
   ```bash
   helm repo update openbao
   helm search repo openbao/openbao --versions
   ```

2. **Review Changes**
   ```bash
   # See what will change
   helm diff upgrade openbao openbao/openbao -f values.yaml
   
   # Get current values
   helm get values openbao > current-values.yaml
   ```

3. **Perform Upgrade**
   ```bash
   # Upgrade to latest version
   helm upgrade openbao openbao/openbao -f values.yaml
   
   # Upgrade to specific version
   helm upgrade openbao openbao/openbao --version 0.14.0 -f values.yaml
   ```

4. **Verify Upgrade**
   ```bash
   # Check rollout status
   kubectl rollout status statefulset/openbao
   
   # Verify OpenBao is unsealed
   kubectl exec openbao-0 -- bao status
   
   # Check version
   kubectl exec openbao-0 -- bao version
   ```

## Version-Specific Upgrade Notes

### Upgrading to 0.14.0 (Future Release)

**Breaking Changes:**
- TBD

**Migration Steps:**
1. TBD

### Upgrading to 0.13.0

**Breaking Changes:**
- Changed default image repository from `vault` to `openbao`
- Annotation prefix changed from `vault.hashicorp.com/` to `openbao.openbao.org/`

**Migration Steps:**
1. Update image references in values.yaml
2. Update pod annotations for agent injection
3. Update any scripts using `vault` CLI to use `bao`

### Upgrading from Vault Helm Chart

See [MIGRATION.md](./MIGRATION.md) for detailed instructions on migrating from HashiCorp Vault.

## Upgrade Strategies

### Rolling Upgrade (Recommended for HA)

For HA deployments with Raft or Consul storage:

```bash
# Set update strategy
helm upgrade openbao openbao/openbao \
  --set server.updateStrategyType=RollingUpdate \
  -f values.yaml

# Monitor upgrade progress
watch kubectl get pods -l app.kubernetes.io/name=openbao
```

### Blue-Green Upgrade

For zero-downtime upgrades:

1. **Deploy New Version**
   ```bash
   # Deploy new version with different name
   helm install openbao-new openbao/openbao \
     --version 0.14.0 \
     -f values-new.yaml
   ```

2. **Migrate Traffic**
   ```bash
   # Update service selector or ingress
   kubectl patch service openbao -p '{"spec":{"selector":{"release":"openbao-new"}}}'
   ```

3. **Cleanup Old Version**
   ```bash
   helm uninstall openbao-old
   ```

### Canary Upgrade

For gradual rollouts:

```yaml
# Deploy canary with subset of replicas
server:
  ha:
    replicas: 1
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/name: openbao
              canary: "false"
```

## OpenBao Binary Upgrades

### Compatibility Matrix

| Chart Version | OpenBao Version | Kubernetes Version | Helm Version |
|--------------|-----------------|-------------------|--------------|
| 0.13.x       | 2.2.x          | 1.30+            | 3.12+       |
| 0.12.x       | 2.1.x          | 1.29+            | 3.10+       |
| 0.11.x       | 2.0.x          | 1.28+            | 3.8+        |

### Upgrading OpenBao Version Only

To upgrade just the OpenBao binary version:

```bash
# Update OpenBao version
helm upgrade openbao openbao/openbao \
  --reuse-values \
  --set server.image.tag="2.2.2"
```

## Storage Backend Considerations

### Raft Storage

**Before Upgrade:**
```bash
# Create Raft snapshot
kubectl exec openbao-0 -- bao operator raft snapshot save /tmp/pre-upgrade.snap

# Download snapshot
kubectl cp openbao-0:/tmp/pre-upgrade.snap ./backups/pre-upgrade-$(date +%s).snap
```

**After Upgrade:**
```bash
# Verify Raft peers
kubectl exec openbao-0 -- bao operator raft list-peers

# Check autopilot status
kubectl exec openbao-0 -- bao operator raft autopilot state
```

### Consul Storage

**Considerations:**
- Ensure Consul cluster is healthy before upgrade
- Check Consul ACL tokens are valid
- Verify network connectivity to Consul

```bash
# Check Consul connection
kubectl exec openbao-0 -- bao status | grep Storage
```

### File Storage

**Warning:** Not recommended for HA deployments

```bash
# Backup file storage
kubectl exec openbao-0 -- tar -czf /tmp/file-backup.tar.gz /openbao/data

# Copy backup
kubectl cp openbao-0:/tmp/file-backup.tar.gz ./backups/
```

## Troubleshooting Upgrades

### Common Issues

#### Pods Stuck in Pending

```bash
# Check PVC issues
kubectl describe pvc data-openbao-0

# Check node resources
kubectl describe node
```

#### Seal/Unseal Issues

```bash
# Manual unseal if auto-unseal fails
kubectl exec -it openbao-0 -- bao operator unseal

# Check seal configuration
kubectl exec openbao-0 -- cat /openbao/config/extraconfig-from-values.hcl | grep seal
```

#### Leader Election Issues

```bash
# Force leader step-down
kubectl exec openbao-0 -- bao operator step-down

# Check HA status
for i in 0 1 2; do
  echo "=== openbao-$i ==="
  kubectl exec openbao-$i -- bao status
done
```

### Rollback Procedure

If upgrade fails:

1. **Quick Rollback**
   ```bash
   # Rollback to previous release
   helm rollback openbao
   
   # Verify rollback
   helm history openbao
   ```

2. **Full Restoration**
   ```bash
   # Restore from Raft snapshot
   kubectl exec openbao-0 -- bao operator raft snapshot restore /tmp/backup.snap
   
   # Verify data integrity
   kubectl exec openbao-0 -- bao list secret/
   ```

## Best Practices

### 1. Staged Rollouts

Always upgrade in this order:
1. Development environment
2. Staging environment
3. Production (canary)
4. Production (full)

### 2. Backup Verification

```bash
# Test snapshot restoration in separate cluster
bao operator raft snapshot restore backup.snap

# Verify critical paths exist
bao list secret/
bao read sys/policies/acl
```

### 3. Health Checks

Create automated health checks:

```bash
#!/bin/bash
# health-check.sh

# Check seal status
SEALED=$(kubectl exec openbao-0 -- bao status -format=json | jq -r '.sealed')
if [ "$SEALED" = "true" ]; then
  echo "ERROR: OpenBao is sealed"
  exit 1
fi

# Check leader exists
LEADER=$(kubectl exec openbao-0 -- bao operator raft list-peers | grep leader)
if [ -z "$LEADER" ]; then
  echo "ERROR: No Raft leader"
  exit 1
fi

echo "OpenBao cluster healthy"
```

### 4. Communication Plan

Before upgrading:
- Notify users of maintenance window
- Document rollback procedures
- Have escalation path ready
- Test communication channels

## Monitoring During Upgrades

### Key Metrics to Watch

```yaml
# Prometheus queries
- alert: OpenBaoUpgradeInProgress
  expr: |
    kube_deployment_status_replicas_updated{deployment="openbao"} 
    != kube_deployment_status_replicas{deployment="openbao"}
  
- alert: OpenBaoHighErrorRate
  expr: |
    rate(vault_core_handle_request_count{error="true"}[5m]) > 0.05
```

### Logs to Monitor

```bash
# Watch upgrade logs
kubectl logs -f statefulset/openbao --all-containers

# Check for errors
kubectl logs openbao-0 | grep -i error

# Monitor audit logs
kubectl exec openbao-0 -- tail -f /openbao/audit/audit.log
```

## Post-Upgrade Tasks

1. **Verify Functionality**
   ```bash
   # Test authentication
   bao login -method=kubernetes
   
   # Test secret access
   bao kv get secret/test
   
   # Verify policies
   bao policy list
   ```

2. **Update Documentation**
   - Record upgrade date and version
   - Note any issues encountered
   - Update runbooks

3. **Clean Up**
   ```bash
   # Remove old backups after verification
   # Update monitoring dashboards
   # Review and update alerts
   ```

## Getting Help

If you encounter issues:

1. Check [GitHub Issues](https://github.com/openbao/openbao-helm/issues)
2. Join [OpenBao Community Chat](https://chat.lfx.linuxfoundation.org)
3. Review [OpenBao Docs](https://openbao.org/docs/)
4. Contact [OpenBao Mailing List](https://lists.openssf.org/g/openbao)