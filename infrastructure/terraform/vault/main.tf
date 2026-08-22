terraform {
  backend "kubernetes" {
    secret_suffix = "vault-state"
    config_path   = "~/.kube/config"
    namespace     = "vault"
  }
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

provider "vault" {
  address = "http://vault.whatsoever.au"
  # Authentication is handled safely via the VAULT_TOKEN environment variable in your terminal
}

# 1. Enable Kubernetes Auth
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# 2. Configure the K3s Connection
resource "vault_kubernetes_auth_backend_config" "k3s" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc:443"
}

# 3. Create the Policy
# ESO is the platform secret broker for all apps. Grant it read across the kv
# (v2) mount rather than enumerating one path per app (which is what caused the
# tailscale/marga sync failures). Note: this is the OLD path was "secret/data/n8n"
# on the default mount - the live mount is "kv", so this also corrects that drift.
# Per-tenant tightening (a Marga-scoped role bound to the marga namespace SA) is
# a separate control tracked for the data-protection gate (B-R1-GATE).
resource "vault_policy" "eso_policy" {
  name   = "eso-policy"
  policy = <<EOT
path "kv/data/*" {
  capabilities = ["read"]
}
path "kv/metadata/*" {
  capabilities = ["read"]
}
EOT
}

# 4. Create the Role (The Bridge)
resource "vault_kubernetes_auth_backend_role" "eso_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "eso-role"
  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = ["external-secrets"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.eso_policy.name]
}

