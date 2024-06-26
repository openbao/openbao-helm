#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


OUTPUT=/tmp/output.txt

bao operator init -n 1 -t 1 >> ${OUTPUT?}

unseal=$(cat ${OUTPUT?} | grep "Unseal Key 1:" | sed -e "s/Unseal Key 1: //g")
root=$(cat ${OUTPUT?} | grep "Initial Root Token:" | sed -e "s/Initial Root Token: //g")

bao operator unseal ${unseal?}

bao login -no-print ${root?}

bao policy write db-backup /openbao/userconfig/test/pgdump-policy.hcl

bao auth enable kubernetes

bao write auth/kubernetes/config \
   token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
   kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \
   kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

bao write auth/kubernetes/role/db-backup \
    bound_service_account_names=pgdump \
    bound_service_account_namespaces=acceptance \
    policies=db-backup \
    ttl=1h

bao secrets enable database

bao write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="db-backup" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/mydb?sslmode=disable" \
    username="openbao" \
    password="openbao"

bao write database/roles/db-backup \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT CONNECT ON DATABASE mydb TO \"{{name}}\"; \
        GRANT USAGE ON SCHEMA app TO \"{{name}}\"; \
        GRANT SELECT ON ALL TABLES IN SCHEMA app TO \"{{name}}\";" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    default_ttl="1h" \
    max_ttl="24h"
