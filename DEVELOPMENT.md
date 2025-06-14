# Development Guide

This guide provides detailed instructions for developing and contributing to the OpenBao Helm chart.

## Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Debugging](#debugging)
- [Release Process](#release-process)
- [Best Practices](#best-practices)

## Development Environment Setup

### Prerequisites

1. **Required Tools**
   ```bash
   # Helm 3.12+
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   
   # kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   
   # yq (for YAML processing)
   pip install yq
   
   # Bats (for testing)
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   ./install.sh /usr/local
   ```

2. **Kubernetes Cluster**
   
   Options for local development:
   ```bash
   # Kind (recommended)
   kind create cluster --name openbao-dev --config test/kind/config.yaml
   
   # Minikube
   minikube start --memory=4096 --cpus=2
   
   # Docker Desktop
   # Enable Kubernetes in Docker Desktop settings
   ```

3. **Development Dependencies**
   ```bash
   # Install pre-commit hooks
   pip install pre-commit
   pre-commit install
   
   # Install helm plugins
   helm plugin install https://github.com/databus23/helm-diff
   helm plugin install https://github.com/quintush/helm-unittest
   ```

### Repository Setup

```bash
# Clone the repository
git clone https://github.com/openbao/openbao-helm.git
cd openbao-helm

# Add upstream remote
git remote add upstream https://github.com/openbao/openbao-helm.git

# Create feature branch
git checkout -b feature/my-new-feature
```

## Project Structure

```
openbao-helm/
├── charts/
│   └── openbao/
│       ├── Chart.yaml          # Chart metadata
│       ├── values.yaml         # Default values
│       ├── values.schema.json  # Values JSON schema
│       ├── README.md          # Chart documentation
│       └── templates/         # Kubernetes templates
│           ├── _helpers.tpl   # Template helpers
│           ├── server-*.yaml  # Server resources
│           ├── injector-*.yaml # Injector resources
│           └── csi-*.yaml     # CSI resources
├── test/
│   ├── unit/                  # Bats unit tests
│   ├── acceptance/            # Acceptance tests
│   └── terraform/            # Test infrastructure
├── examples/                  # Example configurations
├── Makefile                  # Build automation
└── CONTRIBUTING.md           # Contribution guidelines
```

## Development Workflow

### Making Changes

1. **Update Templates**
   ```bash
   # Edit template files
   vim charts/openbao/templates/server-statefulset.yaml
   
   # Test template rendering
   helm template ./charts/openbao --debug
   
   # Check specific values
   helm template ./charts/openbao --set server.ha.enabled=true
   ```

2. **Update Values**
   ```bash
   # Edit values.yaml
   vim charts/openbao/values.yaml
   
   # Update schema if needed
   vim charts/openbao/values.schema.json
   
   # Validate schema
   helm lint ./charts/openbao
   ```

3. **Update Documentation**
   ```bash
   # Auto-generate values documentation
   helm-docs --chart-search-root=charts
   
   # Update examples
   vim examples/ha-raft/values.yaml
   ```

### Local Testing

```bash
# Lint the chart
make lint

# Run unit tests
make test-unit

# Install chart locally
helm install openbao ./charts/openbao \
  --namespace openbao \
  --create-namespace \
  --values test/values-dev.yaml

# Upgrade chart
helm upgrade openbao ./charts/openbao \
  --namespace openbao \
  --values test/values-dev.yaml

# Check resources
kubectl -n openbao get all
kubectl -n openbao describe pod openbao-0
kubectl -n openbao logs openbao-0
```

## Testing

### Unit Tests

Unit tests use Bats and don't require a Kubernetes cluster:

```bash
# Run all unit tests
bats test/unit

# Run specific test file
bats test/unit/server-statefulset.bats

# Run tests matching pattern
bats test/unit -f "server.*storage"

# Run with Docker
docker build -t openbao-helm-test test/docker
docker run -it --rm -v "${PWD}:/test" openbao-helm-test bats /test/test/unit
```

### Writing Unit Tests

Example test structure:
```bash
#!/usr/bin/env bats

load _helpers

@test "server/StatefulSet: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/StatefulSet: custom resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.resources.requests.memory=256Mi' \
      --set 'server.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]
}
```

### Acceptance Tests

Acceptance tests require a running Kubernetes cluster:

```bash
# Set up test cluster
kind create cluster --name openbao-test

# Run acceptance tests
bats test/acceptance

# Run specific acceptance test
bats test/acceptance/server.bats

# Clean up
kind delete cluster --name openbao-test
```

### Test Infrastructure

For complex testing scenarios:

```bash
# Use Terraform to create test infrastructure
cd test/terraform
terraform init
terraform apply -auto-approve

# Run tests against infrastructure
export KUBECONFIG="$(terraform output -raw kubeconfig_path)"
bats test/acceptance

# Clean up
terraform destroy -auto-approve
```

## Debugging

### Common Debugging Commands

```bash
# Check helm template output
helm template openbao ./charts/openbao --debug > rendered.yaml

# Dry run installation
helm install openbao ./charts/openbao --dry-run --debug

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Describe resources
kubectl describe statefulset/openbao
kubectl describe pod/openbao-0

# View logs
kubectl logs openbao-0 -f
kubectl logs openbao-0 -c openbao-init
kubectl logs deployment/openbao-agent-injector

# Execute commands in pod
kubectl exec -it openbao-0 -- bao status
kubectl exec -it openbao-0 -- cat /openbao/config/extraconfig-from-values.hcl

# Port forwarding for debugging
kubectl port-forward openbao-0 8200:8200
```

### Troubleshooting Chart Issues

1. **Template Rendering Errors**
   ```bash
   # Validate templates
   helm template ./charts/openbao --debug --validate
   
   # Check specific values
   helm template ./charts/openbao --set server.ha.enabled=true --debug
   ```

2. **Installation Failures**
   ```bash
   # Check helm release status
   helm status openbao -n openbao
   
   # View helm release history
   helm history openbao -n openbao
   
   # Rollback if needed
   helm rollback openbao -n openbao
   ```

3. **Resource Issues**
   ```bash
   # Check resource usage
   kubectl top pod -n openbao
   
   # Check PVC status
   kubectl get pvc -n openbao
   
   # Check service endpoints
   kubectl get endpoints -n openbao
   ```

## Release Process

### Version Bumping

1. **Update Chart Version**
   ```bash
   # Update Chart.yaml
   vim charts/openbao/Chart.yaml
   # Bump version: 0.13.2 -> 0.13.3
   # Update appVersion if OpenBao version changed
   ```

2. **Update Documentation**
   ```bash
   # Update CHANGELOG.md
   vim CHANGELOG.md
   
   # Regenerate README
   helm-docs --chart-search-root=charts
   ```

### Creating a Release

1. **Tag the Release**
   ```bash
   git tag -a v0.13.3 -m "Release v0.13.3"
   git push origin v0.13.3
   ```

2. **Package Chart**
   ```bash
   helm package charts/openbao
   # Creates openbao-0.13.3.tgz
   ```

3. **Update Helm Repository**
   ```bash
   # This is typically automated via GitHub Actions
   # Manual process:
   helm repo index . --url https://openbao.github.io/openbao-helm
   ```

### Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in Chart.yaml
- [ ] Examples tested with new version
- [ ] Upgrade path tested
- [ ] Release notes prepared

## Best Practices

### Chart Development

1. **Use Helpers**
   ```yaml
   # Good: Use template helpers
   app.kubernetes.io/name: {{ include "openbao.name" . }}
   
   # Bad: Hardcode values
   app.kubernetes.io/name: openbao
   ```

2. **Provide Defaults**
   ```yaml
   # Good: Safe defaults with ability to override
   replicas: {{ .Values.server.ha.replicas | default 3 }}
   
   # Bad: No defaults
   replicas: {{ .Values.server.ha.replicas }}
   ```

3. **Validate Input**
   ```yaml
   # Good: Validate required values
   {{- if and .Values.server.ha.enabled (not .Values.server.ha.raft.enabled) (not .Values.server.ha.config) }}
   {{- fail "server.ha.config is required when not using Raft storage" }}
   {{- end }}
   ```

### Testing Best Practices

1. **Test Edge Cases**
   - Empty values
   - Invalid configurations
   - Resource limits
   - Security contexts

2. **Test Combinations**
   - HA with different storage backends
   - TLS enabled/disabled
   - Various auth methods

3. **Performance Testing**
   ```bash
   # Load test with k6 or similar
   k6 run test/performance/load-test.js
   ```

### Documentation

1. **Document All Values**
   - Purpose of each value
   - Valid options
   - Default behavior
   - Examples

2. **Provide Examples**
   - Common scenarios
   - Production configurations
   - Integration patterns

3. **Keep README Current**
   - Run helm-docs after changes
   - Update examples
   - Test all commands

### Security Considerations

1. **Default Security**
   ```yaml
   # Enable security by default
   securityContext:
     runAsNonRoot: true
     runAsUser: 100
     fsGroup: 1000
   ```

2. **Validate Inputs**
   ```yaml
   # Sanitize user input
   {{- $port := .Values.server.service.port | int }}
   {{- if or (lt $port 1) (gt $port 65535) }}
   {{- fail "Invalid port number" }}
   {{- end }}
   ```

3. **Secret Management**
   - Never log secrets
   - Use Kubernetes secrets
   - Support external secret providers

## Getting Help

- **OpenBao Chat**: https://chat.lfx.linuxfoundation.org
- **GitHub Issues**: https://github.com/openbao/openbao-helm/issues
- **Mailing List**: openbao@lists.openssf.org

## Additional Resources

- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [OpenBao Documentation](https://openbao.org/docs/)
- [Bats Documentation](https://bats-core.readthedocs.io/)