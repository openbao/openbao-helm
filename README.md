# OpenBao Helm Chart

> :warning: **Please note**: We take OpenBao's security and our users' trust very seriously. If
> you believe you have found a security issue in OpenBao Helm, _please responsibly disclose_
> by contacting us at [openbao-security@lists.openssf.org](mailto:openbao-security@lists.openssf.org).

This repository contains the OpenBao Helm chart for installing
and configuring OpenBao on Kubernetes. This chart supports multiple use
cases of OpenBao on Kubernetes depending on the values provided.

## Prerequisites

To use the charts here, [Helm](https://helm.sh/) must be configured for your
Kubernetes cluster. Setting up Kubernetes and Helm is outside the scope of
this README. Please refer to the Kubernetes and Helm documentation.

The versions required are:

- **Helm 3.12+** - Earliest version tested
- **Kubernetes 1.30+** - This is the earliest version of Kubernetes tested.
  It is possible that this chart works with earlier versions but it is
  untested.

In general, the latest versions of widely adopted Kubernetes distributions such
as SUSE Rancher or Red Hat OpenShift are supported.

## Usage

To install the latest version of this chart, add the OpenBao helm repository and run `helm install`:

```console
helm repo add openbao https://openbao.github.io/openbao-helm

helm install openbao openbao/openbao
```

Alternatively you can use the OCI based helm chart as well:

```
helm install oci://ghcr.io/openbao/charts/openbao
```

Please see the many options supported in the [`values.yaml`](https://github.com/openbao/openbao-helm/blob/main/charts/openbao/values.yaml) file. These are also fully documented directly in the [openbao README](https://github.com/openbao/openbao-helm/blob/main/charts/openbao/README.md) along with more detailed installation instructions.

## Verifying Chart Provenance and Integrity

All OpenBao chart artifacts are signed so that provenance and integrity can be verified. See the instructions to verify artifact signatures for your chosen installation method below.

### Helm Repository
To verify the OpenBao chart when using the standard Helm repository.
```bash
curl -sSL https://github.com/openbao/openbao-helm/blob/main/pubring.asc | gpg --import

helm install --verify openbao openbao/openbao
```

### Helm OCI Registry
When using the OCI registry, [Cosign](https://docs.sigstore.dev/cosign/) can be used to verify the OCI artifact.
```bash
cosign verify \
    --certificate-identity='https://github.com/openbao/openbao-helm/.github/workflows/release-chart.yml@refs/heads/main' \
    --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
    ghcr.io/openbao/charts/openbao:0.29.4
```

### Open Component Model
The [Open Component Model](https://ocm.software/) (OCM) artifact can be verified using Cosign.
```bash
ocm verify componentversions \
    --keyless \
    --signature default \
    ghcr.io/openbao//openbao.org/openbao:0.29.4

```
