# High Availability OpenBao with Raft Storage

This example demonstrates deploying OpenBao in High Availability mode using integrated Raft storage.

## Overview

This configuration deploys:
- 3 OpenBao servers in HA mode
- Integrated Raft storage (no external dependencies)
- Auto-unseal using AWS KMS (optional)
- Load-balanced access to active node
- Pod disruption budgets for stability

## Prerequisites

- Kubernetes cluster (3+ nodes recommended)
- kubectl configured
- Helm 3.x installed
- AWS KMS key (if using auto-unseal)

## Deployment Steps

### 1. Configure AWS KMS Auto-Unseal (Optional)

If using AWS KMS auto-unseal, ensure your nodes have appropriate IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
  ]
}
```

### 2. Deploy OpenBao HA Cluster

```bash
# Review and modify values.yaml as needed
helm install openbao openbao/openbao -f values.yaml
```

### 3. Initialize the Raft Cluster

```bash
# Wait for all pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=openbao --timeout=300s

# Initialize the first node
kubectl exec openbao-0 -- bao operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > init-keys.json

# Extract root token and unseal keys
export VAULT_TOKEN=$(cat init-keys.json | jq -r '.root_token')
```

### 4. Join Nodes to Raft Cluster

If not using auto-unseal, unseal the first node:
```bash
kubectl exec openbao-0 -- bao operator unseal <unseal-key-1>
kubectl exec openbao-0 -- bao operator unseal <unseal-key-2>
kubectl exec openbao-0 -- bao operator unseal <unseal-key-3>
```

Join the other nodes:
```bash
kubectl exec openbao-1 -- bao operator raft join http://openbao-0.openbao-internal:8200
kubectl exec openbao-2 -- bao operator raft join http://openbao-0.openbao-internal:8200
```

### 5. Verify Cluster Status

```bash
# Check raft peer list
kubectl exec openbao-0 -- bao operator raft list-peers

# Check cluster status
kubectl exec openbao-0 -- bao status
```

### 6. Configure Load Balanced Access

```bash
# Access via the active service
kubectl port-forward svc/openbao-active 8200:8200

# Or use the standby service for read operations
kubectl port-forward svc/openbao-standby 8200:8200
```

## Production Considerations

### High Availability Features

1. **Automatic Failover**: If the leader fails, a new leader is elected automatically
2. **Request Forwarding**: Standby nodes forward write requests to the active node
3. **Consistent Replication**: All data is replicated across all nodes

### Backup and Recovery

Create regular Raft snapshots:
```bash
# Create snapshot
kubectl exec openbao-0 -- bao operator raft snapshot save /tmp/raft.snap

# Download snapshot
kubectl cp openbao-0:/tmp/raft.snap ./backups/raft-$(date +%Y%m%d-%H%M%S).snap
```

Restore from snapshot:
```bash
# Upload and restore snapshot
kubectl cp ./backups/raft-backup.snap openbao-0:/tmp/restore.snap
kubectl exec openbao-0 -- bao operator raft snapshot restore /tmp/restore.snap
```

### Scaling the Cluster

To add more nodes:
```bash
# Scale the statefulset
kubectl scale statefulset openbao --replicas=5

# Join new nodes to cluster
kubectl exec openbao-3 -- bao operator raft join http://openbao-0.openbao-internal:8200
kubectl exec openbao-4 -- bao operator raft join http://openbao-0.openbao-internal:8200
```

### Monitoring

Monitor cluster health:
```bash
# Check all nodes
for i in 0 1 2; do
  echo "=== openbao-$i ==="
  kubectl exec openbao-$i -- bao status
done

# View logs
kubectl logs -f openbao-0
```

## Troubleshooting

### Node Won't Join Cluster
- Ensure network connectivity between pods
- Check that the leader is unsealed and running
- Verify the join address is correct

### Split Brain Scenario
- Check `bao operator raft list-peers` on each node
- Remove problematic peers: `bao operator raft remove-peer <node-id>`
- Rejoin nodes to cluster

### Performance Issues
- Monitor resource usage: `kubectl top pod -l app.kubernetes.io/name=openbao`
- Consider increasing resource limits
- Check storage performance

## Cleanup

```bash
# Delete the deployment
helm uninstall openbao

# Delete persistent volumes (WARNING: This deletes all data!)
kubectl delete pvc -l app.kubernetes.io/name=openbao
```