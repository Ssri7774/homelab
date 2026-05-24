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
resource "vault_policy" "eso_policy" {
  name   = "eso-policy"
  policy = <<EOT
path "secret/data/n8n" {
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

