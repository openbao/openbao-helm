TEST_IMAGE?=openbao-helm-test
# set to run a single test - e.g acceptance/server-ha-raft.bats
ACCEPTANCE_TESTS?=acceptance
# glob of helm-unittest suites to run, relative to the chart directory.
UNIT_TESTS?=tests/*_test.yaml
# kind cluster name
KIND_CLUSTER_NAME?=openbao-helm
# kind k8s version
KIND_K8S_VERSION?=v1.30.10

# Generate json schema for chart values. See test/README.md for more details.
.PHONY: values-schema
values-schema:
	helm schema-gen values.yaml > values.schema.json

.PHONY: test-image
test-image:
	@docker build --rm -t $(TEST_IMAGE) -f $(CURDIR)/test/docker/Test.dockerfile $(CURDIR)

.PHONY: test-unit
test-unit:
	@docker run --rm -it -v ${PWD}:/helm-test $(TEST_IMAGE) \
		helm unittest --strict -f '$(UNIT_TESTS)' /helm-test/charts/openbao

.PHONY: test
test: test-image test-unit test-acceptance

.PHONY: test-acceptance
test-acceptance: setup-kind
	bats --tap --timing test/${ACCEPTANCE_TESTS}

# create a kind cluster for running the acceptance tests locally
.PHONY: setup-kind
setup-kind:
	kind get clusters | grep -q "^${KIND_CLUSTER_NAME}$$" || \
	kind create cluster \
	--image kindest/node:${KIND_K8S_VERSION} \
	--name ${KIND_CLUSTER_NAME}  \
	--config $(CURDIR)/test/kind/config.yaml
	kubectl config use-context kind-${KIND_CLUSTER_NAME}

# delete the kind cluster
.PHONY: delete-kind
delete-kind:
	kind delete cluster --name ${KIND_CLUSTER_NAME} || :
