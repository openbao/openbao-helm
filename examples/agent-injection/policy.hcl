# Policy for webapp to read secrets
path "secret/data/webapp/*" {
  capabilities = ["read", "list"]
}

# Allow reading metadata
path "secret/metadata/webapp/*" {
  capabilities = ["read", "list"]
}

# If using database secrets engine
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