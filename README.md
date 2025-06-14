# OpenBao Helm Chart

[![License](https://img.shields.io/badge/License-MPL%202.0-blue.svg)](https://opensource.org/licenses/MPL-2.0)
[![Release](https://img.shields.io/github/v/release/openbao/openbao-helm?display_name=tag)](https://github.com/openbao/openbao-helm/releases)
[![Chart Version](https://img.shields.io/badge/Chart%20Version-0.13.2-green.svg)](./charts/openbao/Chart.yaml)

> :warning: **Security Notice**: We take OpenBao's security and our users' trust very seriously. If
> you believe you have found a security issue in OpenBao Helm, _please responsibly disclose_
> by contacting us at [openbao-security@lists.openssf.org](mailto:openbao-security@lists.openssf.org).

## Overview

This repository contains the official OpenBao Helm chart for deploying [OpenBao](https://openbao.org) on Kubernetes. OpenBao is a community-driven, open-source fork of HashiCorp Vault, providing secure secret storage and management.

### Key Features

- 🔐 **Multiple Storage Backends**: File, Consul, Raft, and more
- 🚀 **High Availability**: Multi-server deployments with leader election
- 💉 **Agent Injection**: Automatic secret injection into pods
- 📦 **CSI Provider**: Mount secrets as volumes using Kubernetes CSI
- 🔄 **Auto-Unseal**: Cloud KMS integration for automatic unsealing
- 📊 **Monitoring**: Prometheus metrics and ServiceMonitor support
- 🌐 **Multi-Mode**: Dev, Standalone, and HA configurations

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Modes](#deployment-modes)
- [Architecture](#architecture)
- [Production Considerations](#production-considerations)
- [Migration from Vault](#migration-from-vault)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

### Required
- **Kubernetes** `>= 1.30.0` - Earlier versions may work but are untested
- **Helm** `>= 3.12.0` - For chart installation
- **kubectl** - For cluster interaction

### Optional
- **Consul** - For Consul storage backend (HA mode)
- **secrets-store-csi-driver** - For CSI provider functionality
- **Prometheus Operator** - For metrics and monitoring

### Resource Requirements

| Component | CPU Request | Memory Request | Storage |
|-----------|-------------|----------------|---------|
| Server (Dev) | 250m | 256Mi | None |
| Server (Prod) | 500m | 512Mi | 10Gi+ |
| Injector | 250m | 256Mi | None |
| CSI Provider | 100m | 128Mi | None |

## Quick Start

### Development Mode (⚠️ Not for Production)

```bash
# Add the OpenBao Helm repository
helm repo add openbao https://openbao.github.io/openbao-helm
helm repo update

# Install in dev mode with UI
helm install openbao openbao/openbao \
  --set server.dev.enabled=true \
  --set server.dev.devRootToken=root \
  --set ui.enabled=true

# Access the UI
kubectl port-forward svc/openbao-ui 8200:8200
# Open http://localhost:8200 and login with token: root
```

### Standalone Production

```bash
# Install with persistent storage
helm install openbao openbao/openbao \
  --set server.standalone.enabled=true \
  --set server.dataStorage.enabled=true \
  --set server.dataStorage.size=10Gi \
  --set ui.enabled=true

# Initialize OpenBao
kubectl exec -it openbao-0 -- bao operator init

# Unseal OpenBao (repeat with 3 different keys)
kubectl exec -it openbao-0 -- bao operator unseal
```

### High Availability with Raft

```bash
# Install HA cluster with Raft storage
helm install openbao openbao/openbao \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true \
  --set server.ha.replicas=3 \
  --set ui.enabled=true

# Initialize the first node
kubectl exec -it openbao-0 -- bao operator init

# Join other nodes to the cluster
kubectl exec -it openbao-1 -- bao operator raft join http://openbao-0.openbao-internal:8200
kubectl exec -it openbao-2 -- bao operator raft join http://openbao-0.openbao-internal:8200
```

## Deployment Modes

### Comparison Table

| Mode | Use Case | Storage | HA | Auto-Unseal | Production Ready |
|------|----------|---------|-------|-------------|------------------|
| **Dev** | Testing/Development | In-memory | ❌ | ❌ | ❌ |
| **Standalone** | Single instance | File | ❌ | ✅ | ✅* |
| **HA with Consul** | Multi-instance | Consul | ✅ | ✅ | ✅ |
| **HA with Raft** | Multi-instance | Integrated Raft | ✅ | ✅ | ✅ |

*With proper backup strategy

### Development Mode

Perfect for testing and development:
- No initialization required
- In-memory storage (data lost on restart)
- Single instance only
- UI enabled by default

### Standalone Mode

Suitable for small deployments:
- Persistent file storage
- Single server instance
- Lower resource requirements
- Simple backup/restore

### High Availability Modes

#### HA with Consul
- External Consul cluster required
- Proven, battle-tested storage
- Separate storage layer management

#### HA with Raft (Recommended)
- Integrated storage (no external dependencies)
- Simplified operations
- Automatic leader election
- Built-in data replication

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │ OpenBao     │  │ OpenBao     │  │ OpenBao     │       │
│  │ Server 0    │◄─┤ Server 1    ├─►│ Server 2    │       │
│  │ (Leader)    │  │ (Standby)   │  │ (Standby)   │       │
│  └──────┬──────┘  └─────────────┘  └─────────────┘       │
│         │                                                   │
│         ▼                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  Agent      │  │    CSI      │  │     UI      │       │
│  │  Injector   │  │  Provider   │  │   Service   │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Traffic Flow

1. **Client Requests** → Load Balancer → Active OpenBao Server
2. **Agent Injection** → Mutating Webhook → Inject Sidecar → Fetch Secrets
3. **CSI Volume** → CSI Driver → OpenBao CSI Provider → Mount Secrets

## Production Considerations

### Security Best Practices

1. **Enable TLS**
   ```yaml
   global:
     tlsDisable: false
   ```

2. **Use Auto-Unseal**
   ```yaml
   server:
     seal:
       type: "gcpckms"
       config: |
         project = "my-project"
         region = "global"
         key_ring = "openbao-kr"
         crypto_key = "openbao-key"
   ```

3. **Enable Audit Logging**
   ```yaml
   server:
     auditStorage:
       enabled: true
       size: "10Gi"
   ```

4. **Network Policies**
   ```yaml
   server:
     networkPolicy:
       enabled: true
   ```

### High Availability Checklist

- [ ] Minimum 3 server replicas
- [ ] Pod disruption budgets configured
- [ ] Resource requests and limits set
- [ ] Persistent storage for data and audit logs
- [ ] Regular backup schedule
- [ ] Monitoring and alerting configured
- [ ] Auto-unseal configured
- [ ] TLS enabled for all traffic

### Backup and Recovery

#### Raft Storage Snapshots
```bash
# Create snapshot
kubectl exec openbao-0 -- bao operator raft snapshot save /tmp/snapshot.snap

# Copy snapshot locally
kubectl cp openbao-0:/tmp/snapshot.snap ./openbao-backup-$(date +%Y%m%d).snap

# Restore snapshot
kubectl cp ./openbao-backup.snap openbao-0:/tmp/restore.snap
kubectl exec openbao-0 -- bao operator raft snapshot restore /tmp/restore.snap
```

### Monitoring

Enable Prometheus metrics:
```yaml
serverTelemetry:
  serviceMonitor:
    enabled: true
  prometheusRules:
    enabled: true
    rules:
      - alert: OpenBaoSealed
        expr: up{job="openbao"} == 0
        for: 5m
```

## Migration from Vault

### Key Differences

| Feature | Vault Helm | OpenBao Helm |
|---------|------------|--------------|
| **Binary** | `vault` | `bao` |
| **Image** | `hashicorp/vault` | `openbao/openbao` |
| **Docs** | vault.io | openbao.org |
| **License** | BSL | MPL-2.0 |

### Migration Steps

1. **Export existing data** (if applicable)
2. **Update image references** in values.yaml
3. **Change command references** from `vault` to `bao`
4. **Update documentation links**
5. **Test in non-production first**

See [MIGRATION.md](./MIGRATION.md) for detailed instructions.

## Troubleshooting

### Common Issues

#### Pod Stuck in Pending
```bash
# Check PVC status
kubectl get pvc -l app.kubernetes.io/name=openbao

# Check events
kubectl describe pod openbao-0
```

#### OpenBao is Sealed
```bash
# Check seal status
kubectl exec openbao-0 -- bao status

# Unseal
kubectl exec openbao-0 -- bao operator unseal
```

#### Agent Injection Not Working
```bash
# Check webhook certificate
kubectl get secret openbao-agent-injector-certs -o yaml

# Check webhook configuration
kubectl get mutatingwebhookconfigurations
```

### Useful Commands

```bash
# View logs
kubectl logs -f openbao-0

# Check configuration
kubectl get cm openbao-config -o yaml

# List Raft peers
kubectl exec openbao-0 -- bao operator raft list-peers

# Debug pod
kubectl debug openbao-0 -it --image=busybox
```

## Examples

Comprehensive examples are available in the [`examples/`](./examples/) directory:

- [Standalone with TLS](./examples/standalone-tls/)
- [HA with Raft](./examples/ha-raft/)
- [Auto-unseal with AWS KMS](./examples/auto-unseal-aws/)
- [Agent Injection](./examples/agent-injection/)
- [CSI Provider](./examples/csi-provider/)
- [Monitoring Setup](./examples/monitoring/)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development

```bash
# Run unit tests
make test-unit

# Run acceptance tests (requires cluster)
make test-acceptance

# Lint chart
make lint
```

## Support

- 📚 [Documentation](https://openbao.org/docs/)
- 💬 [Community Chat](https://chat.lfx.linuxfoundation.org)
- 📧 [Mailing List](https://lists.openssf.org/g/openbao)
- 🐛 [Issue Tracker](https://github.com/openbao/openbao-helm/issues)

## License

This project is licensed under the [Mozilla Public License 2.0](LICENSE).