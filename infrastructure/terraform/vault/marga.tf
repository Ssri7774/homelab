# B-R1-11 piece 1: Marga-scoped Vault role (least privilege).
#
# WHY: every ExternalSecret in the cluster reads Vault through ONE identity,
# eso-role -> eso-policy, which grants read on kv/data/* (every app's secrets).
# The Marga namespace now gets its own identity that can read only its own
# paths. The shared eso-role/eso-policy in main.tf is deliberately UNCHANGED, so
# every other app (n8n, forgejo-runner, tailscale, monitoring, cert-manager,
# probadiess, zitadel, marga-backup) keeps working exactly as before.
#
# HOW IT IS USED: apps/marga/secretstore-vault-marga.yaml is a NAMESPACED
# SecretStore in `marga` that authenticates with the ServiceAccount
# marga/marga-eso (apps/marga/serviceaccount-eso.yaml). ESO mints a short-lived
# token for that SA (TokenRequest) and logs in to THIS role. Same auth method,
# same Vault kubernetes backend as the working ClusterSecretStore; only the SA,
# the namespace and the policy differ.
#
# NOT FLUX: Vault config in this repo is Terraform, applied by hand from a
# machine with VAULT_TOKEN (see main.tf). Flux only reconciles ./apps. So this
# file is committed for history and applied with `terraform apply`; it must be
# applied BEFORE the Flux commit that points Marga's ExternalSecrets at the new
# store, or those ExternalSecrets go SecretSyncedError (the Secrets are
# deletionPolicy: Retain, so the app keeps running either way).
#
# Rollback: revert the Flux commits first (3/9 then 2/9) (ExternalSecrets back to vault-backend),
# then `terraform destroy -target=vault_kubernetes_auth_backend_role.marga
# -target=vault_policy.marga` (or just leave them; an unused role grants nothing).

resource "vault_policy" "marga" {
  name   = "marga-policy"
  policy = <<EOT
# Marga's own secrets (KV v2 under mount "kv": data lives at kv/data/<path>).
# ESO reads a remoteRef with a single GET on kv/data/<key>; it does not need
# kv/metadata/* for plain remoteRef lookups, so metadata is NOT granted.
path "kv/data/marga/*" {
  capabilities = ["read"]
}

# kv/marga/zitadel holds the IdP's masterkey and the zitadel-pg superuser
# password. No ExternalSecret in the marga namespace uses it (only the zitadel
# namespace does, via the shared store), and the app namespace must never be
# able to read the IdP's crown jewels. An explicit deny beats the glob above.
# The trailing * also denies any future marga/zitadel-* or marga/zitadel/...
path "kv/data/marga/zitadel*" {
  capabilities = ["deny"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "marga" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "marga-role"
  bound_service_account_names      = ["marga-eso"]
  bound_service_account_namespaces = ["marga"]
  # ESO logs in again whenever it needs a token, so a short TTL costs nothing.
  token_ttl     = 600
  token_max_ttl = 1200
  token_policies = [vault_policy.marga.name]
  # token_no_default_policy is deliberately left false: ESO's SecretStore
  # validation (auth/token/lookup-self) and token revoke-self rely on the
  # default policy. audience is left unset to match eso-role, whose identical
  # TokenRequest flow is proven in production; set both sides together if ever.
}
