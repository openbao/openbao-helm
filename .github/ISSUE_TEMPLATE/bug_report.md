---
name: Bug report
about: Let us know about a bug!
title: ''
labels: bug
assignees: ''

---

<!-- Please reserve GitHub issues for bug reports and feature requests.

**Please note**: We take OpenBao's security and our users' trust very seriously. If
you believe you have found a security issue in OpenBao Helm, _please responsibly disclose_
by contacting us at [openbao-security@lists.openssf.org](mailto:openbao-security@lists.openssf.org).

-->

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Install chart
2. Run bao command
3. See error (openbao logs, etc.)

Other useful info to include: openbao pod logs, `kubectl describe statefulset openbao` and `kubectl get statefulset openbao -o yaml` output

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment**
* Kubernetes version:
  * Distribution or cloud vendor (OpenShift, EKS, GKE, AKS, etc.):
  * Other configuration options or runtime services (istio, etc.):
* openbao-helm version:

Chart values:

```yaml
# Paste your user-supplied values here (`helm get values <release>`).
# Be sure to scrub any sensitive values!
```

**Additional context**
Add any other context about the problem here.
