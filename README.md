# Automated Incident Response Lab

> **Brief Description:** > An automated infrastructure for distributed security monitoring. This project deploys a Wazuh EDR environment across multiple nodes using Ansible and Vagrant, focusing on active threat detection and real-time incident response.

---

## 📋 Table of Contents
1. [Architecture](#architecture)
2. [Environments and IP Addresses](#environments-and-ip-addresses)
3. [Directory Structure](#directory-structure)
4. [Components](#components)
5. [Prerequisites](#prerequisites)
6. [Getting Started](#getting-started)
7. [Secrets](#secrets)
8. [Security Measures](#security-measures)
9. [Security Analysis](#security-analysis)
10. [Verification](#verification)
11. [Design Choices and Justification](#design-choices-and-justification)

---

## Architecture

<img width="1263" height="697" alt="Skärmbild 2026-05-04 130712" src="https://github.com/user-attachments/assets/b0bf18ef-9185-4a25-aaf6-b0cf3d94b2af" />


```

---

## 🌐 Environments and IP Addresses

| VM Name | Role | IP Address | Port Forwarding | Description |
| :--- | :--- | :--- | :--- | :--- |
| `wazuh-manager` | Central Server | `192.168.56.10` | `:443 → host:8443` | Handles alerts, indexing, and the dashboard. |
| `wazuh-agent` | Monitored System | `192.168.56.11` | — | Target client running EDR agent and monitoring. |

---

## 📁 Directory Structure

```text
repo/
├── vagrant/
│   ├── Vagrantfile          # Defines VMs and network settings
│   └── secrets.yml          # [GITIGNORED] - Passwords and sensitive values
├── ansible/
│   ├── inventory.ini        # Defines hosts and groups for Ansible
│   ├── site.yml             # Master playbook - runs all roles
│   ├── roles/
│   │   ├── wazuh-manager/   # Installs the server stack
│   │   ├── wazuh-agent/     # Installs and registers the agent
│   │   └── attacker/        # Scripts for brute-force simulation
├── docs/
│   └── architecture.png     # Architecture diagram
├── .gitignore
└── README.md
```

---

## ⚙️ Components

### Vagrantfile
Defines the virtual machines in VirtualBox. It uses environment variables for network bridges to ensure compatibility across different host environments.

### Ansible Configuration
* **inventory.ini:** Groups the servers into functional units.
* **site.yml:** Orchestrates the deployment order (Manager first, then Agent).

### Ansible Roles
* **wazuh-manager:** Sets up the Wazuh Indexer, Dashboard, and Manager.
* **wazuh-agent:** Registers the agent with the manager and configures monitoring rules.
* **attacker:** Contains tools to simulate security events (e.g., SSH brute-force).

---

## 🛠 Prerequisites

**Software:**
* VirtualBox (7.x+)
* Vagrant (2.x+)
* Ansible (installed locally or via control node)

**Hardware Requirements:**
* Minimum **8 GB RAM** (The manager stack is resource-intensive).
* **20 GB** free disk space (recommended on external storage, e.g., `E:/Lab_Storage`).

---

## 🚀 Getting Started

```bash
# 1. Clone the repository
git clone <url>
cd automated-incident-response-lab

# 2. Configure environment variables (Windows PowerShell)
$env:VAGRANT_BRIDGE = "Wi-Fi"

# 3. Start and provision the environment
vagrant up
```

---

## 🔐 Secrets
Sensitive variables are managed via `ansible/group_vars/all.yml` or a local `secrets.yml`. 
> [!CAUTION]
> Never commit `secrets.yml` to version control. Use `secrets_example.yml` as a template.

---

## 🛡 Security Measures

| Measure | Scope | Status |
| :--- | :--- | :--- |
| SSH Key Auth Only | All VMs | ✅ Automated |
| UFW Firewall | Wazuh Manager | ✅ Only essential ports open |
| Active Response | Wazuh Agent | ✅ Automatic IP blocking during attacks |
| TLS Encryption | Dashboard | ✅ Internal self-signed certs |

---

## 🔍 Security Analysis

### Remaining Weaknesses
1.  **Self-signed Certificates:** The dashboard uses SSL but without a public CA, which is acceptable for lab environments.
2.  **Local Logging:** Logs are stored locally on the manager; a production environment would require off-site log shipping.

### Protection Layers
* **Network Segmentation:** Only the manager node exposes a web interface.
* **Automation:** Zero manual intervention reduces the risk of human-induced misconfiguration.

---

## Verification

Dashboard is accessible at [https://192.168.56.10](https://192.168.56.10) (or https://localhost:8443 if using port forwarding). Log in using the admin credentials found in wazuh-passwords.txt after deployment.

To verify that the lab is functioning correctly, run the verification script:
```bash
bash scripts/verify.sh
```

**Expected Results:**
* Wazuh Dashboard is reachable at `https://localhost:8443`.
* The agent appears as "Active" in the dashboard.
* A simulated brute-force attack triggers "Active Response" (IP is blocked).

---

## Design Choices and Justification

To ensure system stability across reboots, the implementation of idempotent Ansible playboks is in use.

* **EDR Selection (Wazuh):** Chosen for its robust ability to combine log analysis with active, real-time response.
* **Infrastructure as Code (IaC):** Allows for rapid tear-down and re-deployment, which promotes a "Green IT" approach by only keeping the lab active when needed.

---
**Created by:** Karin Ekenberg & Sandra Victorsson  
**Course:** Virtualization and Automation  
**Date:** 2026-04-29
