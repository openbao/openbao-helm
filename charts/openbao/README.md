# openbao

![Version: 0.13.2](https://img.shields.io/badge/Version-0.13.2-informational?style=flat-square) ![AppVersion: v2.2.2](https://img.shields.io/badge/AppVersion-v2.2.2-informational?style=flat-square)

Official OpenBao Chart

**Homepage:** <https://github.com/openbao/openbao-helm>

## Overview

This Helm chart deploys OpenBao on Kubernetes with support for:
- **Standalone Mode**: Single OpenBao server with file storage
- **High Availability Mode**: Multi-server setup with Consul backend
- **Raft Mode**: Multi-server setup with integrated Raft storage
- **Agent Injection**: Automatic secret injection into pods
- **CSI Provider**: Mount secrets as volumes using secrets-store-csi-driver

## Prerequisites

- Kubernetes `>= 1.30.0-0`
- Helm 3.x
- For CSI: [secrets-store-csi-driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver) must be installed separately

## Installation

### Quick Start - Standalone Mode

Deploy a single OpenBao server with UI enabled:

```bash
helm repo add openbao https://openbao.github.io/openbao-helm
helm install openbao openbao/openbao --set ui.enabled=true
```

### Development Mode

For testing and development (NOT for production):

```bash
helm install openbao openbao/openbao \
  --set server.dev.enabled=true \
  --set server.dev.devRootToken=myroot \
  --set ui.enabled=true
```

## Deployment Configurations

### 1. Standalone Mode (Default)

Single OpenBao server with file storage:

```yaml
# values-standalone.yaml
server:
  standalone:
    enabled: true
    config: |
      ui = true
      
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      
      storage "file" {
        path = "/openbao/data"
      }

ui:
  enabled: true
  serviceType: "LoadBalancer"  # or NodePort/ClusterIP

server:
  dataStorage:
    enabled: true
    size: "10Gi"
    storageClass: "standard"  # adjust for your cluster
```

Deploy:
```bash
helm install openbao openbao/openbao -f values-standalone.yaml
```

### 2. High Availability with Consul

Multi-server setup using Consul for storage:

```yaml
# values-ha-consul.yaml
server:
  ha:
    enabled: true
    replicas: 3
    config: |
      ui = true
      
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      
      storage "consul" {
        path = "openbao"
        address = "consul:8500"
      }
      
      service_registration "kubernetes" {}

ui:
  enabled: true

# Requires Consul to be deployed separately
```

Deploy:
```bash
# First deploy Consul
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install consul hashicorp/consul

# Then deploy OpenBao
helm install openbao openbao/openbao -f values-ha-consul.yaml
```

### 3. High Availability with Raft

Multi-server setup using integrated Raft storage:

```yaml
# values-ha-raft.yaml
server:
  ha:
    enabled: true
    raft:
      enabled: true
      setNodeId: true
    replicas: 3
    config: |
      ui = true
      
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      
      storage "raft" {
        path = "/openbao/data"
      }
      
      service_registration "kubernetes" {}

ui:
  enabled: true

server:
  dataStorage:
    enabled: true
    size: "10Gi"
```

Deploy:
```bash
helm install openbao openbao/openbao -f values-ha-raft.yaml
```

### 4. External OpenBao Server

Use with existing OpenBao server:

```yaml
# values-external.yaml
global:
  externalVaultAddr: "https://my-openbao.example.com:8200"

server:
  enabled: false

injector:
  enabled: true
  # Agent injection only

csi:
  enabled: true
  # CSI provider only
```

## Advanced Configurations

### Auto-Unseal with Cloud KMS

Example using Google Cloud KMS:

```yaml
# values-auto-unseal.yaml
server:
  standalone:
    config: |
      ui = true
      
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      
      storage "file" {
        path = "/openbao/data"
      }
      
      seal "gcpckms" {
        project     = "my-project"
        region      = "global"
        key_ring    = "openbao-kr"
        crypto_key  = "openbao-key"
      }

# Ensure your cluster has appropriate GCP service account permissions
```

### Enable Agent Injection

Automatically inject secrets into pods:

```yaml
# values-injection.yaml
injector:
  enabled: true
  agentImage:
    repository: "openbao/openbao"
    tag: "2.2.2"
  
  # Configure defaults for injected agents
  agentDefaults:
    cpuRequest: "250m"
    cpuLimit: "500m"
    memRequest: "64Mi"
    memLimit: "128Mi"

# Example pod annotation for injection:
# openbao.openbao.org/agent-inject: "true"
# openbao.openbao.org/agent-inject-secret-db: "database/creds/readonly"
```

### Enable CSI Provider

Mount secrets as files using CSI driver:

```yaml
# values-csi.yaml
csi:
  enabled: true
  image:
    repository: "hashicorp/vault-csi-provider"
    tag: "1.4.0"

# Requires secrets-store-csi-driver to be installed:
# helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
# helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver
```

### Production-Ready Configuration

```yaml
# values-production.yaml
global:
  tlsDisable: false  # Enable TLS

server:
  ha:
    enabled: true
    raft:
      enabled: true
    replicas: 5
  
  # Resource limits
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "256Mi"
      cpu: "250m"
  
  # Persistent storage
  dataStorage:
    enabled: true
    size: "50Gi"
    storageClass: "ssd"
  
  auditStorage:
    enabled: true
    size: "20Gi"
    storageClass: "ssd"
  
  # Network policies
  networkPolicy:
    enabled: true
  
  # Pod disruption budget
  ha:
    disruptionBudget:
      enabled: true
      maxUnavailable: 1

# Monitoring
serverTelemetry:
  serviceMonitor:
    enabled: true
    interval: "30s"
  prometheusRules:
    enabled: true

ui:
  enabled: true
  serviceType: "LoadBalancer"

injector:
  enabled: true
  replicas: 2
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "256Mi"
      cpu: "250m"
```

## Post-Installation Steps

### 1. Initialize OpenBao (Standalone/HA)

```bash
# Port forward to access OpenBao
kubectl port-forward svc/openbao 8200:8200

# Initialize OpenBao
bao operator init

# Unseal OpenBao (repeat for each unseal key)
bao operator unseal
```

### 2. Initialize Raft Cluster

```bash
# Initialize the first node
kubectl exec -it openbao-0 -- bao operator init

# Join other nodes to the cluster
kubectl exec -it openbao-1 -- bao operator raft join http://openbao-0.openbao-internal:8200
kubectl exec -it openbao-2 -- bao operator raft join http://openbao-0.openbao-internal:8200
```

### 3. Configure Kubernetes Auth

```bash
# Enable Kubernetes auth method
bao auth enable kubernetes

# Configure Kubernetes auth
bao write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

## Upgrading

```bash
# Update Helm repository
helm repo update

# Upgrade with new values
helm upgrade openbao openbao/openbao -f values.yaml

# Check rollout status
kubectl rollout status statefulset/openbao
```

## Troubleshooting

### Common Issues

1. **Pod stuck in pending**: Check storage class and PVC creation
2. **OpenBao sealed**: Run `bao operator unseal` on each pod
3. **Agent injection not working**: Verify webhook certificates and RBAC
4. **CSI mount failures**: Ensure secrets-store-csi-driver is installed

### Useful Commands

```bash
# Check OpenBao status
kubectl exec -it openbao-0 -- bao status

# View OpenBao logs
kubectl logs openbao-0

# Check configuration
kubectl get configmap openbao-config -o yaml

# List Raft peers
kubectl exec -it openbao-0 -- bao operator raft list-peers
```

## Security Considerations

- **Always enable TLS in production** (`global.tlsDisable: false`)
- **Use auto-unseal for production workloads**
- **Enable audit logging** (`server.auditStorage.enabled: true`)
- **Implement network policies** (`server.networkPolicy.enabled: true`)
- **Use dedicated service accounts with minimal permissions**
- **Regularly rotate unseal keys and root tokens**

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| OpenBao | <openbao-security@lists.openssf.org> | <https://openbao.org> |

## Source Code

* <https://github.com/openbao/openbao-helm>

## Requirements

Kubernetes: `>= 1.30.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| csi.agent.enabled | bool | `true` |  |
| csi.agent.extraArgs | list | `[]` |  |
| csi.agent.image.pullPolicy | string | `"IfNotPresent"` | image pull policy to use for agent image. if tag is "latest", set to "Always" |
| csi.agent.image.registry | string | `"quay.io"` | image registry to use for agent image |
| csi.agent.image.repository | string | `"openbao/openbao"` | image repo to use for agent image |
| csi.agent.image.tag | string | `"2.2.2"` | image tag to use for agent image |
| csi.agent.logFormat | string | `"standard"` |  |
| csi.agent.logLevel | string | `"info"` |  |
| csi.agent.resources | object | `{}` |  |
| csi.daemonSet.annotations | object | `{}` |  |
| csi.daemonSet.extraLabels | object | `{}` |  |
| csi.daemonSet.kubeletRootDir | string | `"/var/lib/kubelet"` |  |
| csi.daemonSet.providersDir | string | `"/etc/kubernetes/secrets-store-csi-providers"` |  |
| csi.daemonSet.securityContext.container | object | `{}` |  |
| csi.daemonSet.securityContext.pod | object | `{}` |  |
| csi.daemonSet.updateStrategy.maxUnavailable | string | `""` |  |
| csi.daemonSet.updateStrategy.type | string | `"RollingUpdate"` |  |
| csi.debug | bool | `false` |  |
| csi.enabled | bool | `false` | True if you want to install a secrets-store-csi-driver-provider-vault daemonset.  Requires installing the secrets-store-csi-driver separately, see: https://github.com/kubernetes-sigs/secrets-store-csi-driver#install-the-secrets-store-csi-driver  With the driver and provider installed, you can mount OpenBao secrets into volumes similar to the OpenBao Agent injector, and you can also sync those secrets into Kubernetes secrets. |
| csi.extraArgs | list | `[]` |  |
| csi.hmacSecretName | string | `""` |  |
| csi.image.pullPolicy | string | `"IfNotPresent"` | image pull policy to use for csi image. if tag is "latest", set to "Always" |
| csi.image.registry | string | `"docker.io"` | image registry to use for csi image |
| csi.image.repository | string | `"hashicorp/vault-csi-provider"` | image repo to use for csi image |
| csi.image.tag | string | `"1.4.0"` | image tag to use for csi image |
| csi.livenessProbe.failureThreshold | int | `2` |  |
| csi.livenessProbe.initialDelaySeconds | int | `5` |  |
| csi.livenessProbe.periodSeconds | int | `5` |  |
| csi.livenessProbe.successThreshold | int | `1` |  |
| csi.livenessProbe.timeoutSeconds | int | `3` |  |
| csi.pod.affinity | object | `{}` |  |
| csi.pod.annotations | object | `{}` |  |
| csi.pod.extraLabels | object | `{}` |  |
| csi.pod.nodeSelector | object | `{}` |  |
| csi.pod.tolerations | list | `[]` |  |
| csi.priorityClassName | string | `""` |  |
| csi.readinessProbe.failureThreshold | int | `2` |  |
| csi.readinessProbe.initialDelaySeconds | int | `5` |  |
| csi.readinessProbe.periodSeconds | int | `5` |  |
| csi.readinessProbe.successThreshold | int | `1` |  |
| csi.readinessProbe.timeoutSeconds | int | `3` |  |
| csi.resources | object | `{}` |  |
| csi.serviceAccount.annotations | object | `{}` |  |
| csi.serviceAccount.extraLabels | object | `{}` |  |
| csi.volumeMounts | list | `[]` | volumeMounts is a list of volumeMounts for the main server container. These are rendered via toYaml rather than pre-processed like the extraVolumes value. The purpose is to make it easy to share volumes between containers. |
| csi.volumes | list | `[]` | volumes is a list of volumes made available to all containers. These are rendered via toYaml rather than pre-processed like the extraVolumes value. The purpose is to make it easy to share volumes between containers. |
| global.enabled | bool | `true` | enabled is the master enabled switch. Setting this to true or false will enable or disable all the components within this chart by default. |
| global.externalVaultAddr | string | `""` | External openbao server address for the injector and CSI provider to use. Setting this will disable deployment of a openbao server. |
| global.imagePullSecrets | list | `[]` | Image pull secret to use for registry authentication. Alternatively, the value may be specified as an array of strings. |
| global.namespace | string | `""` | The namespace to deploy to. Defaults to the `helm` installation namespace. |
| global.openshift | bool | `false` | If deploying to OpenShift |
| global.psp | object | `{"annotations":"seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default,runtime/default\napparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default\nseccomp.security.alpha.kubernetes.io/defaultProfileName:  runtime/default\napparmor.security.beta.kubernetes.io/defaultProfileName:  runtime/default\n","enable":false}` | Create PodSecurityPolicy for pods |
| global.psp.annotations | string | `"seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default,runtime/default\napparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default\nseccomp.security.alpha.kubernetes.io/defaultProfileName:  runtime/default\napparmor.security.beta.kubernetes.io/defaultProfileName:  runtime/default\n"` | Annotation for PodSecurityPolicy. This is a multi-line templated string map, and can also be set as YAML. |
| global.serverTelemetry.prometheusOperator | bool | `false` | Enable integration with the Prometheus Operator See the top level serverTelemetry section below before enabling this feature. |
| global.tlsDisable | bool | `true` | TLS for end-to-end encrypted transport |
| injector.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"openbao.name\" . }}-agent-injector\n          app.kubernetes.io/instance: \"{{ .Release.Name }}\"\n          component: webhook\n      topologyKey: kubernetes.io/hostname\n"` |  |
| injector.agentDefaults.cpuLimit | string | `"500m"` |  |
| injector.agentDefaults.cpuRequest | string | `"250m"` |  |
| injector.agentDefaults.memLimit | string | `"128Mi"` |  |
| injector.agentDefaults.memRequest | string | `"64Mi"` |  |
| injector.agentDefaults.template | string | `"map"` |  |
| injector.agentDefaults.templateConfig.exitOnRetryFailure | bool | `true` |  |
| injector.agentDefaults.templateConfig.staticSecretRenderInterval | string | `""` |  |
| injector.agentImage | object | `{"pullPolicy":"IfNotPresent","registry":"quay.io","repository":"openbao/openbao","tag":"2.2.2"}` | agentImage sets the repo and tag of the OpenBao image to use for the OpenBao Agent containers.  This should be set to the official OpenBao image.  OpenBao 1.3.1+ is required. |
| injector.agentImage.pullPolicy | string | `"IfNotPresent"` | image pull policy to use for agent image. if tag is "latest", set to "Always" |
| injector.agentImage.registry | string | `"quay.io"` | image registry to use for agent image |
| injector.agentImage.repository | string | `"openbao/openbao"` | image repo to use for agent image |
| injector.agentImage.tag | string | `"2.2.2"` | image tag to use for agent image |
| injector.annotations | object | `{}` |  |
| injector.authPath | string | `"auth/kubernetes"` |  |
| injector.certs.caBundle | string | `""` |  |
| injector.certs.certName | string | `"tls.crt"` |  |
| injector.certs.keyName | string | `"tls.key"` |  |
| injector.certs.secretName | string | `nil` |  |
| injector.enabled | string | `"-"` | True if you want to enable openbao agent injection. @default: global.enabled |
| injector.externalVaultAddr | string | `""` | Deprecated: Please use global.externalVaultAddr instead. |
| injector.extraEnvironmentVars | object | `{}` |  |
| injector.extraLabels | object | `{}` |  |
| injector.failurePolicy | string | `"Ignore"` |  |
| injector.hostNetwork | bool | `false` |  |
| injector.image.pullPolicy | string | `"IfNotPresent"` | image pull policy to use for k8s image. if tag is "latest", set to "Always" |
| injector.image.registry | string | `"docker.io"` | image registry to use for k8s image |
| injector.image.repository | string | `"hashicorp/vault-k8s"` | image repo to use for k8s image |
| injector.image.tag | string | `"1.4.2"` | image tag to use for k8s image |
| injector.leaderElector | object | `{"enabled":true}` | If multiple replicas are specified, by default a leader will be determined so that only one injector attempts to create TLS certificates. |
| injector.livenessProbe.failureThreshold | int | `2` | When a probe fails, Kubernetes will try failureThreshold times before giving up |
| injector.livenessProbe.initialDelaySeconds | int | `5` | Number of seconds after the container has started before probe initiates |
| injector.livenessProbe.periodSeconds | int | `2` | How often (in seconds) to perform the probe |
| injector.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the probe to be considered successful after having failed |
| injector.livenessProbe.timeoutSeconds | int | `5` | Number of seconds after which the probe times out. |
| injector.logFormat | string | `"standard"` | Configures the log format of the injector. Supported log formats: "standard", "json". |
| injector.logLevel | string | `"info"` | Configures the log verbosity of the injector. Supported log levels include: trace, debug, info, warn, error |
| injector.metrics | object | `{"enabled":false}` | If true, will enable a node exporter metrics endpoint at /metrics. |
| injector.namespaceSelector | object | `{}` |  |
| injector.nodeSelector | object | `{}` |  |
| injector.objectSelector | object | `{}` |  |
| injector.podDisruptionBudget | object | `{}` |  |
| injector.port | int | `8080` | Configures the port the injector should listen on |
| injector.priorityClassName | string | `""` |  |
| injector.readinessProbe.failureThreshold | int | `2` | When a probe fails, Kubernetes will try failureThreshold times before giving up |
| injector.readinessProbe.initialDelaySeconds | int | `5` | Number of seconds after the container has started before probe initiates |
| injector.readinessProbe.periodSeconds | int | `2` | How often (in seconds) to perform the probe |
| injector.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the probe to be considered successful after having failed |
| injector.readinessProbe.timeoutSeconds | int | `5` | Number of seconds after which the probe times out. |
| injector.replicas | int | `1` |  |
| injector.resources | object | `{}` |  |
| injector.revokeOnShutdown | bool | `false` |  |
| injector.securityContext.container | object | `{}` |  |
| injector.securityContext.pod | object | `{}` |  |
| injector.service.annotations | object | `{}` |  |
| injector.serviceAccount.annotations | object | `{}` |  |
| injector.startupProbe.failureThreshold | int | `12` | When a probe fails, Kubernetes will try failureThreshold times before giving up |
| injector.startupProbe.initialDelaySeconds | int | `5` | Number of seconds after the container has started before probe initiates |
| injector.startupProbe.periodSeconds | int | `5` | How often (in seconds) to perform the probe |
| injector.startupProbe.successThreshold | int | `1` | Minimum consecutive successes for the probe to be considered successful after having failed |
| injector.startupProbe.timeoutSeconds | int | `5` | Number of seconds after which the probe times out. |
| injector.strategy | object | `{}` |  |
| injector.tolerations | list | `[]` |  |
| injector.topologySpreadConstraints | list | `[]` |  |
| injector.webhook.annotations | object | `{}` |  |
| injector.webhook.failurePolicy | string | `"Ignore"` |  |
| injector.webhook.matchPolicy | string | `"Exact"` |  |
| injector.webhook.namespaceSelector | object | `{}` |  |
| injector.webhook.objectSelector | string | `"matchExpressions:\n- key: app.kubernetes.io/name\n  operator: NotIn\n  values:\n  - {{ template \"openbao.name\" . }}-agent-injector\n"` |  |
| injector.webhook.timeoutSeconds | int | `30` |  |
| injector.webhookAnnotations | object | `{}` |  |
| server.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"openbao.name\" . }}\n          app.kubernetes.io/instance: \"{{ .Release.Name }}\"\n          component: server\n      topologyKey: kubernetes.io/hostname\n"` |  |
| server.annotations | object | `{}` |  |
| server.auditStorage.accessMode | string | `"ReadWriteOnce"` |  |
| server.auditStorage.annotations | object | `{}` |  |
| server.auditStorage.enabled | bool | `false` |  |
| server.auditStorage.labels | object | `{}` |  |
| server.auditStorage.mountPath | string | `"/openbao/audit"` |  |
| server.auditStorage.size | string | `"10Gi"` |  |
| server.auditStorage.storageClass | string | `nil` |  |
| server.authDelegator.enabled | bool | `true` |  |
| server.configAnnotation | bool | `false` |  |
| server.dataStorage.accessMode | string | `"ReadWriteOnce"` |  |
| server.dataStorage.annotations | object | `{}` |  |
| server.dataStorage.enabled | bool | `true` |  |
| server.dataStorage.labels | object | `{}` |  |
| server.dataStorage.mountPath | string | `"/openbao/data"` |  |
| server.dataStorage.size | string | `"10Gi"` |  |
| server.dataStorage.storageClass | string | `nil` |  |
| server.dev.devRootToken | string | `"root"` |  |
| server.dev.enabled | bool | `false` |  |
| server.enabled | string | `"-"` |  |
| server.extraArgs | string | `""` | extraArgs is a string containing additional OpenBao server arguments. |
| server.extraContainers | string | `nil` |  |
| server.extraEnvironmentVars | object | `{}` |  |
| server.extraInitContainers | list | `[]` | extraInitContainers is a list of init containers. Specified as a YAML list. This is useful if you need to run a script to provision TLS certificates or write out configuration files in a dynamic way. |
| server.extraLabels | object | `{}` |  |
| server.extraPorts | list | `[]` | extraPorts is a list of extra ports. Specified as a YAML list. This is useful if you need to add additional ports to the statefulset in dynamic way. |
| server.extraSecretEnvironmentVars | list | `[]` |  |
| server.extraVolumes | list | `[]` |  |
| server.ha.apiAddr | string | `nil` |  |
| server.ha.clusterAddr | string | `nil` |  |
| server.ha.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n}\nstorage \"consul\" {\n  path = \"openbao\"\n  address = \"HOST_IP:8500\"\n}\n\nservice_registration \"kubernetes\" {}\n\n# Example configuration for using auto-unseal, using Google Cloud KMS. The\n# GKMS keys must already exist, and the cluster must have a service account\n# that is authorized to access GCP KMS.\n#seal \"gcpckms\" {\n#   project     = \"openbao-helm-dev-246514\"\n#   region      = \"global\"\n#   key_ring    = \"openbao-helm-unseal-kr\"\n#   crypto_key  = \"openbao-helm-unseal-key\"\n#}\n\n# Example configuration for enabling Prometheus metrics.\n# If you are using Prometheus Operator you can enable a ServiceMonitor resource below.\n# You may wish to enable unauthenticated metrics in the listener block above.\n#telemetry {\n#  prometheus_retention_time = \"30s\"\n#  disable_hostname = true\n#}\n"` |  |
| server.ha.disruptionBudget.enabled | bool | `true` |  |
| server.ha.disruptionBudget.maxUnavailable | string | `nil` |  |
| server.ha.enabled | bool | `false` |  |
| server.ha.raft.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n  # Enable unauthenticated metrics access (necessary for Prometheus Operator)\n  #telemetry {\n  #  unauthenticated_metrics_access = \"true\"\n  #}\n}\n\nstorage \"raft\" {\n  path = \"/openbao/data\"\n}\n\nservice_registration \"kubernetes\" {}\n"` |  |
| server.ha.raft.enabled | bool | `false` |  |
| server.ha.raft.setNodeId | bool | `false` |  |
| server.ha.replicas | int | `3` |  |
| server.hostAliases | list | `[]` |  |
| server.hostNetwork | bool | `false` |  |
| server.image.pullPolicy | string | `"IfNotPresent"` | image pull policy to use for server image. if tag is "latest", set to "Always" |
| server.image.registry | string | `"quay.io"` | image registry to use for server image |
| server.image.repository | string | `"openbao/openbao"` | image repo to use for server image |
| server.image.tag | string | `"2.2.2"` | image tag to use for server image |
| server.ingress.activeService | bool | `true` |  |
| server.ingress.annotations | object | `{}` |  |
| server.ingress.enabled | bool | `false` |  |
| server.ingress.extraPaths | list | `[]` |  |
| server.ingress.hosts[0].host | string | `"chart-example.local"` |  |
| server.ingress.hosts[0].paths | list | `[]` |  |
| server.ingress.ingressClassName | string | `""` |  |
| server.ingress.labels | object | `{}` |  |
| server.ingress.pathType | string | `"Prefix"` |  |
| server.ingress.tls | list | `[]` |  |
| server.livenessProbe.enabled | bool | `false` |  |
| server.livenessProbe.execCommand | list | `[]` |  |
| server.livenessProbe.failureThreshold | int | `2` |  |
| server.livenessProbe.initialDelaySeconds | int | `60` |  |
| server.livenessProbe.path | string | `"/v1/sys/health?standbyok=true"` |  |
| server.livenessProbe.periodSeconds | int | `5` |  |
| server.livenessProbe.port | int | `8200` |  |
| server.livenessProbe.successThreshold | int | `1` |  |
| server.livenessProbe.timeoutSeconds | int | `3` |  |
| server.logFormat | string | `""` |  |
| server.logLevel | string | `""` |  |
| server.networkPolicy.egress | list | `[]` |  |
| server.networkPolicy.enabled | bool | `false` |  |
| server.networkPolicy.ingress[0].from[0].namespaceSelector | object | `{}` |  |
| server.networkPolicy.ingress[0].ports[0].port | int | `8200` |  |
| server.networkPolicy.ingress[0].ports[0].protocol | string | `"TCP"` |  |
| server.networkPolicy.ingress[0].ports[1].port | int | `8201` |  |
| server.networkPolicy.ingress[0].ports[1].protocol | string | `"TCP"` |  |
| server.nodeSelector | object | `{}` |  |
| server.persistentVolumeClaimRetentionPolicy | object | `{}` |  |
| server.postStart | list | `[]` |  |
| server.preStopSleepSeconds | int | `5` |  |
| server.priorityClassName | string | `""` |  |
| server.readinessProbe.enabled | bool | `true` |  |
| server.readinessProbe.failureThreshold | int | `2` |  |
| server.readinessProbe.initialDelaySeconds | int | `5` |  |
| server.readinessProbe.periodSeconds | int | `5` |  |
| server.readinessProbe.port | int | `8200` |  |
| server.readinessProbe.successThreshold | int | `1` |  |
| server.readinessProbe.timeoutSeconds | int | `3` |  |
| server.resources | object | `{}` |  |
| server.route.activeService | bool | `true` |  |
| server.route.annotations | object | `{}` |  |
| server.route.enabled | bool | `false` |  |
| server.route.host | string | `"chart-example.local"` |  |
| server.route.labels | object | `{}` |  |
| server.route.tls.termination | string | `"passthrough"` |  |
| server.service.active.annotations | object | `{}` |  |
| server.service.active.enabled | bool | `true` |  |
| server.service.annotations | object | `{}` |  |
| server.service.enabled | bool | `true` |  |
| server.service.externalTrafficPolicy | string | `"Cluster"` |  |
| server.service.instanceSelector.enabled | bool | `true` |  |
| server.service.ipFamilies | list | `[]` |  |
| server.service.ipFamilyPolicy | string | `""` |  |
| server.service.port | int | `8200` |  |
| server.service.publishNotReadyAddresses | bool | `true` |  |
| server.service.standby.annotations | object | `{}` |  |
| server.service.standby.enabled | bool | `true` |  |
| server.service.targetPort | int | `8200` |  |
| server.serviceAccount.annotations | object | `{}` |  |
| server.serviceAccount.create | bool | `true` |  |
| server.serviceAccount.createSecret | bool | `false` |  |
| server.serviceAccount.extraLabels | object | `{}` |  |
| server.serviceAccount.name | string | `""` |  |
| server.serviceAccount.serviceDiscovery.enabled | bool | `true` |  |
| server.shareProcessNamespace | bool | `false` | shareProcessNamespace enables process namespace sharing between OpenBao and the extraContainers This is useful if OpenBao must be signaled, e.g. to send a SIGHUP for a log rotation |
| server.standalone.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n  # Enable unauthenticated metrics access (necessary for Prometheus Operator)\n  #telemetry {\n  #  unauthenticated_metrics_access = \"true\"\n  #}\n}\nstorage \"file\" {\n  path = \"/openbao/data\"\n}\n\n# Example configuration for using auto-unseal, using Google Cloud KMS. The\n# GKMS keys must already exist, and the cluster must have a service account\n# that is authorized to access GCP KMS.\n#seal \"gcpckms\" {\n#   project     = \"openbao-helm-dev\"\n#   region      = \"global\"\n#   key_ring    = \"openbao-helm-unseal-kr\"\n#   crypto_key  = \"openbao-helm-unseal-key\"\n#}\n\n# Example configuration for enabling Prometheus metrics in your config.\n#telemetry {\n#  prometheus_retention_time = \"30s\"\n#  disable_hostname = true\n#}\n"` |  |
| server.standalone.enabled | string | `"-"` |  |
| server.statefulSet.annotations | object | `{}` |  |
| server.statefulSet.securityContext.container | object | `{}` |  |
| server.statefulSet.securityContext.pod | object | `{}` |  |
| server.terminationGracePeriodSeconds | int | `10` |  |
| server.tolerations | list | `[]` |  |
| server.topologySpreadConstraints | list | `[]` |  |
| server.updateStrategyType | string | `"OnDelete"` |  |
| server.volumeMounts | string | `nil` |  |
| server.volumes | string | `nil` |  |
| serverTelemetry.prometheusRules.enabled | bool | `false` |  |
| serverTelemetry.prometheusRules.rules | list | `[]` |  |
| serverTelemetry.prometheusRules.selectors | object | `{}` |  |
| serverTelemetry.serviceMonitor.authorization | object | `{}` |  |
| serverTelemetry.serviceMonitor.enabled | bool | `false` |  |
| serverTelemetry.serviceMonitor.interval | string | `"30s"` |  |
| serverTelemetry.serviceMonitor.scrapeClass | string | `""` |  |
| serverTelemetry.serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| serverTelemetry.serviceMonitor.selectors | object | `{}` |  |
| serverTelemetry.serviceMonitor.tlsConfig | object | `{}` |  |
| ui.activeOpenbaoPodOnly | bool | `false` |  |
| ui.annotations | object | `{}` |  |
| ui.enabled | bool | `false` |  |
| ui.externalPort | int | `8200` |  |
| ui.externalTrafficPolicy | string | `"Cluster"` |  |
| ui.publishNotReadyAddresses | bool | `true` |  |
| ui.serviceIPFamilies | list | `[]` |  |
| ui.serviceIPFamilyPolicy | string | `""` |  |
| ui.serviceNodePort | string | `nil` |  |
| ui.serviceType | string | `"ClusterIP"` |  |
| ui.targetPort | int | `8200` |  |
