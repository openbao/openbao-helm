# openbao

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: v2.0.0-alpha20240329](https://img.shields.io/badge/AppVersion-v2.0.0--alpha20240329-informational?style=flat-square)

Official openbao Chart

**Homepage:** <https://github.com/openbao/openbao-helm>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| jessebot |  | <https://github.com/jessebot> |

## Source Code

* <https://github.com/openbao/openbao-helm>

## Requirements

Kubernetes: `>= 1.27.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| csi.agent.enabled | bool | `true` |  |
| csi.agent.extraArgs | list | `[]` |  |
| csi.agent.image.pullPolicy | string | `"IfNotPresent"` |  |
| csi.agent.image.repository | string | `"hashicorp/vault"` |  |
| csi.agent.image.tag | string | `"1.15.2"` |  |
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
| csi.enabled | bool | `false` |  |
| csi.extraArgs | list | `[]` |  |
| csi.hmacSecretName | string | `""` |  |
| csi.image.pullPolicy | string | `"IfNotPresent"` |  |
| csi.image.repository | string | `"hashicorp/vault-csi-provider"` |  |
| csi.image.tag | string | `"1.4.1"` |  |
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
| csi.volumeMounts | string | `nil` |  |
| csi.volumes | string | `nil` |  |
| global.enabled | bool | `true` |  |
| global.externalVaultAddr | string | `""` |  |
| global.imagePullSecrets | list | `[]` |  |
| global.namespace | string | `""` |  |
| global.openshift | bool | `false` |  |
| global.psp.annotations | string | `"seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default,runtime/default\napparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default\nseccomp.security.alpha.kubernetes.io/defaultProfileName:  runtime/default\napparmor.security.beta.kubernetes.io/defaultProfileName:  runtime/default\n"` |  |
| global.psp.enable | bool | `false` |  |
| global.serverTelemetry.prometheusOperator | bool | `false` |  |
| global.tlsDisable | bool | `true` |  |
| injector.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"vault.name\" . }}-agent-injector\n          app.kubernetes.io/instance: \"{{ .Release.Name }}\"\n          component: webhook\n      topologyKey: kubernetes.io/hostname\n"` |  |
| injector.agentDefaults.cpuLimit | string | `"500m"` |  |
| injector.agentDefaults.cpuRequest | string | `"250m"` |  |
| injector.agentDefaults.memLimit | string | `"128Mi"` |  |
| injector.agentDefaults.memRequest | string | `"64Mi"` |  |
| injector.agentDefaults.template | string | `"map"` |  |
| injector.agentDefaults.templateConfig.exitOnRetryFailure | bool | `true` |  |
| injector.agentDefaults.templateConfig.staticSecretRenderInterval | string | `""` |  |
| injector.agentImage.repository | string | `"hashicorp/vault"` |  |
| injector.agentImage.tag | string | `"1.15.2"` |  |
| injector.annotations | object | `{}` |  |
| injector.authPath | string | `"auth/kubernetes"` |  |
| injector.certs.caBundle | string | `""` |  |
| injector.certs.certName | string | `"tls.crt"` |  |
| injector.certs.keyName | string | `"tls.key"` |  |
| injector.certs.secretName | string | `nil` |  |
| injector.enabled | string | `"-"` |  |
| injector.externalVaultAddr | string | `""` |  |
| injector.extraEnvironmentVars | object | `{}` |  |
| injector.extraLabels | object | `{}` |  |
| injector.failurePolicy | string | `"Ignore"` |  |
| injector.hostNetwork | bool | `false` |  |
| injector.image.pullPolicy | string | `"IfNotPresent"` |  |
| injector.image.repository | string | `"hashicorp/vault-k8s"` |  |
| injector.image.tag | string | `"1.3.1"` |  |
| injector.leaderElector.enabled | bool | `true` |  |
| injector.livenessProbe.failureThreshold | int | `2` |  |
| injector.livenessProbe.initialDelaySeconds | int | `5` |  |
| injector.livenessProbe.periodSeconds | int | `2` |  |
| injector.livenessProbe.successThreshold | int | `1` |  |
| injector.livenessProbe.timeoutSeconds | int | `5` |  |
| injector.logFormat | string | `"standard"` |  |
| injector.logLevel | string | `"info"` |  |
| injector.metrics.enabled | bool | `false` |  |
| injector.namespaceSelector | object | `{}` |  |
| injector.nodeSelector | object | `{}` |  |
| injector.objectSelector | object | `{}` |  |
| injector.podDisruptionBudget | object | `{}` |  |
| injector.port | int | `8080` |  |
| injector.priorityClassName | string | `""` |  |
| injector.readinessProbe.failureThreshold | int | `2` |  |
| injector.readinessProbe.initialDelaySeconds | int | `5` |  |
| injector.readinessProbe.periodSeconds | int | `2` |  |
| injector.readinessProbe.successThreshold | int | `1` |  |
| injector.readinessProbe.timeoutSeconds | int | `5` |  |
| injector.replicas | int | `1` |  |
| injector.resources | object | `{}` |  |
| injector.revokeOnShutdown | bool | `false` |  |
| injector.securityContext.container | object | `{}` |  |
| injector.securityContext.pod | object | `{}` |  |
| injector.service.annotations | object | `{}` |  |
| injector.serviceAccount.annotations | object | `{}` |  |
| injector.startupProbe.failureThreshold | int | `12` |  |
| injector.startupProbe.initialDelaySeconds | int | `5` |  |
| injector.startupProbe.periodSeconds | int | `5` |  |
| injector.startupProbe.successThreshold | int | `1` |  |
| injector.startupProbe.timeoutSeconds | int | `5` |  |
| injector.strategy | object | `{}` |  |
| injector.tolerations | list | `[]` |  |
| injector.topologySpreadConstraints | list | `[]` |  |
| injector.webhook.annotations | object | `{}` |  |
| injector.webhook.failurePolicy | string | `"Ignore"` |  |
| injector.webhook.matchPolicy | string | `"Exact"` |  |
| injector.webhook.namespaceSelector | object | `{}` |  |
| injector.webhook.objectSelector | string | `"matchExpressions:\n- key: app.kubernetes.io/name\n  operator: NotIn\n  values:\n  - {{ template \"vault.name\" . }}-agent-injector\n"` |  |
| injector.webhook.timeoutSeconds | int | `30` |  |
| injector.webhookAnnotations | object | `{}` |  |
| server.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"vault.name\" . }}\n          app.kubernetes.io/instance: \"{{ .Release.Name }}\"\n          component: server\n      topologyKey: kubernetes.io/hostname\n"` |  |
| server.annotations | object | `{}` |  |
| server.auditStorage.accessMode | string | `"ReadWriteOnce"` |  |
| server.auditStorage.annotations | object | `{}` |  |
| server.auditStorage.enabled | bool | `false` |  |
| server.auditStorage.labels | object | `{}` |  |
| server.auditStorage.mountPath | string | `"/vault/audit"` |  |
| server.auditStorage.size | string | `"10Gi"` |  |
| server.auditStorage.storageClass | string | `nil` |  |
| server.authDelegator.enabled | bool | `true` |  |
| server.configAnnotation | bool | `false` |  |
| server.dataStorage.accessMode | string | `"ReadWriteOnce"` |  |
| server.dataStorage.annotations | object | `{}` |  |
| server.dataStorage.enabled | bool | `true` |  |
| server.dataStorage.labels | object | `{}` |  |
| server.dataStorage.mountPath | string | `"/vault/data"` |  |
| server.dataStorage.size | string | `"10Gi"` |  |
| server.dataStorage.storageClass | string | `nil` |  |
| server.dev.devRootToken | string | `"root"` |  |
| server.dev.enabled | bool | `false` |  |
| server.enabled | string | `"-"` |  |
| server.enterpriseLicense.secretKey | string | `"license"` |  |
| server.enterpriseLicense.secretName | string | `""` |  |
| server.extraArgs | string | `""` |  |
| server.extraContainers | string | `nil` |  |
| server.extraEnvironmentVars | object | `{}` |  |
| server.extraInitContainers | string | `nil` |  |
| server.extraLabels | object | `{}` |  |
| server.extraPorts | string | `nil` |  |
| server.extraSecretEnvironmentVars | list | `[]` |  |
| server.extraVolumes | list | `[]` |  |
| server.ha.apiAddr | string | `nil` |  |
| server.ha.clusterAddr | string | `nil` |  |
| server.ha.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n}\nstorage \"consul\" {\n  path = \"vault\"\n  address = \"HOST_IP:8500\"\n}\n\nservice_registration \"kubernetes\" {}\n\n# Example configuration for using auto-unseal, using Google Cloud KMS. The\n# GKMS keys must already exist, and the cluster must have a service account\n# that is authorized to access GCP KMS.\n#seal \"gcpckms\" {\n#   project     = \"vault-helm-dev-246514\"\n#   region      = \"global\"\n#   key_ring    = \"vault-helm-unseal-kr\"\n#   crypto_key  = \"vault-helm-unseal-key\"\n#}\n\n# Example configuration for enabling Prometheus metrics.\n# If you are using Prometheus Operator you can enable a ServiceMonitor resource below.\n# You may wish to enable unauthenticated metrics in the listener block above.\n#telemetry {\n#  prometheus_retention_time = \"30s\"\n#  disable_hostname = true\n#}\n"` |  |
| server.ha.disruptionBudget.enabled | bool | `true` |  |
| server.ha.disruptionBudget.maxUnavailable | string | `nil` |  |
| server.ha.enabled | bool | `false` |  |
| server.ha.raft.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n  # Enable unauthenticated metrics access (necessary for Prometheus Operator)\n  #telemetry {\n  #  unauthenticated_metrics_access = \"true\"\n  #}\n}\n\nstorage \"raft\" {\n  path = \"/vault/data\"\n}\n\nservice_registration \"kubernetes\" {}\n"` |  |
| server.ha.raft.enabled | bool | `false` |  |
| server.ha.raft.setNodeId | bool | `false` |  |
| server.ha.replicas | int | `3` |  |
| server.hostAliases | list | `[]` |  |
| server.hostNetwork | bool | `false` |  |
| server.image.pullPolicy | string | `"IfNotPresent"` |  |
| server.image.repository | string | `"hashicorp/vault"` |  |
| server.image.tag | string | `"1.15.2"` |  |
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
| server.shareProcessNamespace | bool | `false` |  |
| server.standalone.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n  # Enable unauthenticated metrics access (necessary for Prometheus Operator)\n  #telemetry {\n  #  unauthenticated_metrics_access = \"true\"\n  #}\n}\nstorage \"file\" {\n  path = \"/vault/data\"\n}\n\n# Example configuration for using auto-unseal, using Google Cloud KMS. The\n# GKMS keys must already exist, and the cluster must have a service account\n# that is authorized to access GCP KMS.\n#seal \"gcpckms\" {\n#   project     = \"vault-helm-dev\"\n#   region      = \"global\"\n#   key_ring    = \"vault-helm-unseal-kr\"\n#   crypto_key  = \"vault-helm-unseal-key\"\n#}\n\n# Example configuration for enabling Prometheus metrics in your config.\n#telemetry {\n#  prometheus_retention_time = \"30s\"\n#  disable_hostname = true\n#}\n"` |  |
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
| serverTelemetry.serviceMonitor.enabled | bool | `false` |  |
| serverTelemetry.serviceMonitor.interval | string | `"30s"` |  |
| serverTelemetry.serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| serverTelemetry.serviceMonitor.selectors | object | `{}` |  |
| ui.activeVaultPodOnly | bool | `false` |  |
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

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
