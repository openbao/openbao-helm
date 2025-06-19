# OpenBao Helm Chart

> :warning: **Please note**: We take OpenBao's security and our users' trust very seriously. If
you believe you have found a security issue in OpenBao Helm, _please responsibly disclose_
by contacting us at [openbao-security@lists.lfedge.org](mailto:openbao-security@lists.lfedge.org).

This repository contains the OpenBao Helm chart for installing
and configuring OpenBao on Kubernetes. This chart supports multiple use
cases of OpenBao on Kubernetes depending on the values provided.

## Prerequisites

To use the charts here, [Helm](https://helm.sh/) must be configured for your
Kubernetes cluster. Setting up Kubernetes and Helm is outside the scope of
this README. Please refer to the Kubernetes and Helm documentation.

The versions required are:

  * **Helm 3.12+** - Earliest verison tested
  * **Kubernetes 1.28+** - This is the earliest version of Kubernetes tested.
    It is possible that this chart works with earlier versions but it is
    untested.

## Usage

To install the latest version of this chart, add the OpenBao helm repository and run `helm install`:

```console
helm repo add openbao https://openbao.github.io/openbao-helm

helm install openbao openbao/openbao
```

Please see the many options supported in the [`values.yaml`](./charts/openbao/values.yaml) file. These are also fully documented directly in the [openbao README](./charts/openbao/README.md) along with more detailed installation instructions.
