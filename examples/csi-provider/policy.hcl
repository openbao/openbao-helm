# Policy for webapp to read secrets via CSI
path "secret/data/webapp/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/webapp/*" {
  capabilities = ["read", "list"]
}

# If using PKI to generate certificates
path "pki/issue/webapp" {
  capabilities = ["create", "update"]
}

# If using dynamic database credentials
path "database/creds/readonly" {
  capabilities = ["read"]
}

# Allow token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow token lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}