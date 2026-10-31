# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This Dockerfile installs all the dependencies necessary to run the unit and
# acceptance tests.
#
# This image has no automatic entrypoint. It is expected that you'll run
# a script to configure kubectl, potentially install Helm, and run the tests
# manually. This image only has the dependencies pre-installed.

FROM docker.mirror.hashicorp.services/alpine:latest
WORKDIR /root

ENV BATS_VERSION "1.3.0"
ENV HELM_UNITTEST_VERSION "1.2.1"

# base packages
RUN apk update && apk add --no-cache --virtual .build-deps \
    ca-certificates \
    curl \
    tar \
    bash \
    openssl \
    py-pip \
    git \
    make \
    jq

# yq
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install yq && \
    ln -s $PWD/venv/bin/yq /usr/local/bin/yq && \
    deactivate

# kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# helm
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# helm-unittest
RUN helm plugin install https://github.com/helm-unittest/helm-unittest.git \
    --version ${HELM_UNITTEST_VERSION}

# bats (acceptance tests)
RUN curl -sSL https://github.com/bats-core/bats-core/archive/v${BATS_VERSION}.tar.gz -o /tmp/bats.tgz \
    && tar -zxf /tmp/bats.tgz -C /tmp \
    && /bin/bash /tmp/bats-core-$BATS_VERSION/install.sh /usr/local
