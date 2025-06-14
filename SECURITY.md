# Security Policy and Best Practices

## Reporting Security Vulnerabilities

We take OpenBao's security and our users' trust very seriously. If you believe you have found a security issue in OpenBao Helm, **please responsibly disclose** by contacting us at:

📧 **openbao-security@lists.openssf.org**

Please do **NOT** file a public issue for security vulnerabilities.

### What to Include

When reporting a security issue, please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fixes (if any)
- Your contact information

## Security Best Practices

This guide provides security best practices for deploying OpenBao using the Helm chart.

### 1. Enable TLS Everywhere

**Never run OpenBao with TLS disabled in production.**

```yaml
global:
  tlsDisable: false

server:
  standalone:
    config: |
      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_cert_file = "/openbao/userconfig/tls/tls.crt"
        tls_key_file = "/openbao/userconfig/tls/tls.key"
        tls_client_ca_file = "/openbao/userconfig/tls/ca.crt"
        tls_min_version = "tls12"
        tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
      }
```

### 2. Implement Auto-Unseal

Avoid manual unsealing in production by using cloud KMS:

```yaml
server:
  ha:
    config: |
      seal "awskms" {
        region = "us-east-1"
        kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        endpoint = "https://kms.us-east-1.amazonaws.com"
      }
```

Supported auto-unseal providers:
- AWS KMS
- Azure Key Vault
- Google Cloud KMS
- Transit (another OpenBao cluster)

### 3. Enable Audit Logging

Always enable audit logging in production:

```yaml
server:
  auditStorage:
    enabled: true
    size: "25Gi"
    storageClass: "fast-ssd"
    
  standalone:
    config: |
      # After initialization, enable audit
      # bao audit enable file file_path=/openbao/audit/audit.log
```

Post-deployment audit configuration:
```bash
# Enable audit logging
bao audit enable file file_path=/openbao/audit/audit.log

# Enable syslog audit
bao audit enable syslog tag="openbao" facility="LOCAL7"

# Enable audit with HMAC
bao audit enable file file_path=/openbao/audit/audit.log hmac_accessor=false
```

### 4. Implement Network Policies

Restrict network traffic between pods:

```yaml
server:
  networkPolicy:
    enabled: true
    ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: openbao
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: openbao
        ports:
        - port: 8200
          protocol: TCP
        - port: 8201
          protocol: TCP
    egress:
      - to:
        - namespaceSelector: {}
        ports:
        - port: 443
          protocol: TCP
        - port: 8500  # Consul
          protocol: TCP
```

### 5. Use Pod Security Standards

Configure security contexts:

```yaml
server:
  statefulSet:
    securityContext:
      pod:
        runAsNonRoot: true
        runAsUser: 100
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      container:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
          add:
            - IPC_LOCK  # Required for mlock
```

### 6. RBAC Configuration

Limit service account permissions:

```yaml
server:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/openbao-kms-unseal"

  authDelegator:
    enabled: true  # Only if using Kubernetes auth
```

### 7. Resource Limits

Always set resource limits to prevent DoS:

```yaml
server:
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

injector:
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

### 8. Secret Management

#### For Kubernetes Secrets
```yaml
# Use encrypted storage class
server:
  dataStorage:
    storageClass: "encrypted-ssd"
    
# Enable encryption at rest in Kubernetes
# kubectl patch storageclass encrypted-ssd -p '{"allowVolumeExpansion": true, "parameters": {"encrypted": "true"}}'
```

#### For TLS Certificates
```yaml
# Use cert-manager for automatic rotation
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: openbao-tls
spec:
  secretName: openbao-tls
  duration: 720h    # 30 days
  renewBefore: 168h # 7 days
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
```

### 9. Authentication Best Practices

#### Kubernetes Auth Configuration
```bash
# Configure with least privilege
bao write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    disable_iss_validation=false

# Bind to specific namespaces and service accounts
bao write auth/kubernetes/role/myapp \
    bound_service_account_names=myapp-sa \
    bound_service_account_namespaces=production \
    policies=myapp-policy \
    ttl=1h \
    max_ttl=24h
```

#### JWT/OIDC Configuration
```bash
# Configure OIDC with bound claims
bao write auth/jwt/role/myapp \
    bound_audiences="https://openbao.company.com" \
    bound_subject="system:serviceaccount:production:myapp" \
    bound_claims='{
      "namespace": "production",
      "serviceaccount": "myapp"
    }' \
    user_claim="sub" \
    policies=myapp-policy \
    ttl=1h
```

### 10. Policy Management

Implement least privilege policies:

```hcl
# Bad: Overly permissive
path "*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Good: Least privilege
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["read", "list"]
}

# Deny by default
path "*" {
  capabilities = ["deny"]
}
```

### 11. Monitoring and Alerting

Enable comprehensive monitoring:

```yaml
serverTelemetry:
  serviceMonitor:
    enabled: true
    interval: "30s"
    
  prometheusRules:
    enabled: true
    rules:
      - alert: OpenBaoSealed
        expr: vault_core_unsealed == 0
        for: 1m
        labels:
          severity: critical
          
      - alert: OpenBaoTooManyFailedLogins
        expr: rate(vault_core_handle_login_request{error="true"}[5m]) > 5
        for: 5m
        labels:
          severity: warning
          
      - alert: OpenBaoCertificateExpiringSoon
        expr: (vault_secret_lease_expiration - time()) < 7 * 24 * 60 * 60
        for: 1h
        labels:
          severity: warning
```

### 12. Hardening Checklist

Before going to production, ensure:

- [ ] TLS enabled for all communications
- [ ] Auto-unseal configured
- [ ] Audit logging enabled
- [ ] Network policies implemented
- [ ] Pod security policies/standards applied
- [ ] Resource limits set
- [ ] RBAC properly configured
- [ ] Regular backups scheduled
- [ ] Monitoring and alerting configured
- [ ] Incident response plan documented
- [ ] Key rotation procedures in place
- [ ] Access logs regularly reviewed

## Security Updates

Stay informed about security updates:

1. **Watch the Repository**: GitHub notifications for releases
2. **Subscribe to Mailing List**: openbao-security@lists.openssf.org
3. **Monitor CVE Databases**: Check for OpenBao-related CVEs
4. **Regular Updates**: Plan regular update cycles

## Compliance Considerations

### Data Residency
```yaml
# Use node selectors for data residency
server:
  nodeSelector:
    topology.kubernetes.io/region: "us-east-1"
    compliance/data-residency: "us"
```

### Encryption Standards
- Use FIPS 140-2 compliant HSMs when required
- Configure TLS 1.2+ only
- Use approved cipher suites

### Audit Requirements
- Enable comprehensive audit logging
- Ship logs to SIEM
- Implement log retention policies
- Regular audit log reviews

## Incident Response

### If Compromise Suspected

1. **Immediate Actions**
   - Seal OpenBao: `bao operator seal`
   - Revoke potentially compromised tokens
   - Review audit logs
   - Isolate affected systems

2. **Investigation**
   - Check audit logs for unauthorized access
   - Review Kubernetes events and logs
   - Analyze network traffic
   - Check for persistence mechanisms

3. **Recovery**
   - Rotate all secrets
   - Regenerate TLS certificates
   - Update access policies
   - Implement additional controls

### Useful Commands

```bash
# Seal OpenBao immediately
kubectl exec -it openbao-0 -- bao operator seal

# Revoke all tokens
kubectl exec -it openbao-0 -- bao token revoke -mode=orphan

# List token accessors
kubectl exec -it openbao-0 -- bao list auth/token/accessors

# Review audit logs
kubectl exec -it openbao-0 -- tail -f /openbao/audit/audit.log | jq

# Generate new root token (requires unseal keys)
kubectl exec -it openbao-0 -- bao operator generate-root
```

## Additional Resources

- [OpenBao Security Model](https://openbao.org/docs/concepts/security/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [NIST Cryptographic Standards](https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)