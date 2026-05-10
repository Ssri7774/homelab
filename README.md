# 🚀 K3s GitOps HomeLab

A fully automated, hybrid physical/virtual Kubernetes HomeLab cluster managed with GitOps principles.

## 🏗 Architecture
This cluster utilizes a hybrid model to maximize resource efficiency and reliability.

*   **Control Plane:** Physical HP Mini PC (`hp-master`) running Ubuntu Server 26.04.
*   **Worker Nodes:** Virtual Machines hosted on a Synology NAS (`syno-worker-01`, `syno-worker-02`).
*   **Distribution:** [K3s](https://k3s.io/) (Lightweight Kubernetes).

## 🛠 Tech Stack
*   **GitOps:** [FluxCD](https://fluxcd.io/) for automated reconciliation of all manifests.
*   **Secret Management:** [HashiCorp Vault](https://www.vaultproject.io/) + [External Secrets Operator (ESO)](https://external-secrets.io/). Secrets are stored securely in Vault and injected into the cluster, ensuring **zero plain-text secrets in Git**.
*   **DNS & Networking:** 
    *   [Technitium DNS](https://technitium.com/dns/) for local domain resolution (`.whatsoever.au`).
    *   [Traefik Proxy](https://traefik.io/) as the Ingress Controller.
    *   [Klipper ServiceLB](https://github.com/k3s-io/klipper-lb) for LoadBalancer services.
*   **Infrastructure as Code:** [Terraform](https://www.terraform.io/) for provisioning cluster components.

## 🚀 Key Applications
*   **n8n:** Workflow automation.
*   **Forgejo:** Self-hosted Git service (mirrored to GitHub for portfolio visibility).
*   **Vault UI:** Secure management of infrastructure credentials.

## 🛡 Security & Resilience
*   **Network Policies:** Fine-grained traffic control using the embedded `kube-router` policy engine.
*   **Persistence:** Automated volume management via K3s Local-Path provisioner.
*   **Auto-Recovery:** Designed to recover networking and DNS automatically after power loss events.

---
*Created by [Sri](https://github.com/Ssri7774) as a showcase of Kubernetes infrastructure and GitOps automation.*
