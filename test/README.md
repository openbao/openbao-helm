# OpenBao Helm Tests

## Running OpenBao Helm Acceptance tests

The Makefile at the top level of this repo contains a few targets that should help with running acceptance tests in a kind cluster.

### Running in a kind cluster

* Run `make test-acceptance` to create or reuse a kind cluster and run the acceptance tests.
* You can choose to only run certain tests by setting the `ACCEPTANCE_TESTS` variable and re-running the above target.
* Run `make delete-kind` when you have finished testing and want to tear-down and remove the cluster.
* You can set an alternate kind cluster name by specifying the `KIND_CLUSTER_NAME` variable for any of the above targets.
* You can set an alternate K8S version by specifying the `KIND_K8S_VERSION` variable for any of the above targets.

See [kind-quick-start](https://kind.sigs.k8s.io/docs/user/quick-start/) if you don't have kind installed on your system.

## Running chart verification tests

If [chart-verifier](https://github.com/redhat-certification/chart-verifier) is built and available in your PATH, run:

    bats test/chart/verifier.bats

Or if you'd rather use the latest chart-verifier docker container, set
USE_DOCKER:

    USE_DOCKER=true bats test/chart/verifier.bats

## Generating the values json schema

There is a make target for generating values.schema.json:

    make values-schema

It relies on the helm [schema-gen plugin][schema-gen]. Note that some manual
editing will be required, since several properties accept multiple data types.

[schema-gen]: https://github.com/karuppiah7890/helm-schema-gen

## Helm test

OpenBao Helm also contains a simple helm test under
[templates/tests/](../templates/tests/) that may be run against a helm release:

    helm test <RELEASE_NAME>
