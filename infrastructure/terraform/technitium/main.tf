terraform {
  backend "kubernetes" {
    secret_suffix = "technitium-state"
    config_path   = "~/.kube/config"
    namespace     = "flux-system"
  }
  required_providers {
    technitium = {
      source  = "kevynb/technitium"
      version = "~> 0.4.0"
    }
  }
}

provider "technitium" {
  url = "http://192.168.4.140:5380"
  # Authentication is handled safely via the TECHNITIUM_TOKEN environment variable
}

# 1. Create the Primary Zone
resource "technitium_zone" "whatsoever" {
  name = "whatsoever.au"
  type = "Primary"
}

# 2. A-Record for n8n
resource "technitium_record" "n8n" {
  domain = "n8n.whatsoever.au"
  zone   = technitium_zone.whatsoever.name
  type   = "A"
  ipv4_address = "192.168.4.140"
}

# 3. A-Record for Vault
resource "technitium_record" "vault" {
  domain = "vault.whatsoever.au"
  zone   = technitium_zone.whatsoever.name
  type   = "A"
  ipv4_address = "192.168.4.140"
}


