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

---

## Environments and IP Addresses

| VM Name | Role | IP Address | Port Forwarding | Description |
| :--- | :--- | :--- | :--- | :--- |
| `wazuh-manager` | Central Server | `192.168.56.10` | `:443 → host:8443` | Handles alerts, indexing, and the dashboard. |
| `web-agent` | Monitored System | `192.168.56.11` | — | Target client running EDR agent and monitoring. |
| `db-agent` | Monitored System | `192.168.56.12` | — | Target client running EDR agent and monitoring. |

---

## Directory Structure
```
automated-incident-response-lab/
├── ansible/
│   ├── files/
│   │   └── wordlist.txt        # Dictionary for brute-force simulations
│   ├── inventory/
│   │   └── hosts.ini          # Target definitions and SSH variables
│   ├── playbooks/
│   │   ├── cleanup.yml        # Removes lab artifacts
│   │   ├── run_attack.yml     # Executes security simulations
│   │   └── setup_target.yml   # Prepares nodes for monitoring
│   ├── roles/
│   │   ├── attack_target/     # Logic for configuring victim nodes
│   │   │   ├── handlers/      # Service restarts (main.yml)
│   │   │   └── tasks/         # Deployment logic (main.yml)
│   │   ├── attacker/          # Logic for the simulation node
│   │   │   ├── tasks/         # Attack scripts deployment
│   │   │   └── templates/     # Dynamic attack scripts (run_attack.sh.j2)
│   │   └── wazuh_agent/       # EDR deployment and log config
│   │       ├── defaults/      # Default role variables
│   │       ├── handlers/      # Agent service management
│   │       ├── tasks/         # Installation and auth.log injection
│   │       └── templates/     # Custom config (ossec.conf.j2)
│   ├── ansible.cfg            # Global Ansible configuration
│   └── site.yml               # Main entry point for orchestration
├── manager_key.pub            # Public key for Wazuh Manager
├── verify.sh                  # Validation script for security events
├── Vagrantfile                # Infrastructure-as-Code VM definition
└── README.md                  # Project documentation
```

---

## Components

### Vagrantfile
Defines the virtual machines in VirtualBox. It uses environment variables for network bridges to ensure compatibility across different host environments.

### Ansible Configuration
* **inventory.ini:** Groups the servers into functional units.
* **site.yml:** Orchestrates the deployment order (Manager first, then Agent).
* 

### Ansible Roles
* **wazuh-manager:** Sets up the Wazuh Indexer, Dashboard, and Manager.
* **wazuh-agent:** Installing the agent, registering it with the manager and configuring **endpoint log collection**. The role injects configurations to monitor /var/log/auth.log to track real-time authentication tracking.
* **attacker:** Contains tools to simulate security events (e.g., SSH brute-force).

---

## Prerequisites

**Software:**
* VirtualBox (7.x+)
* Vagrant (2.x+)
* Ansible (installed locally or via control node)

**Hardware Requirements:**
* Minimum **8 GB RAM** (The manager stack is resource-intensive).
* **20 GB** free disk space (recommended on external storage, e.g., `E:/Lab_Storage`).

---

## Getting Started

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

## Secrets
Sensitive variables are managed via `ansible/group_vars/all.yml` or a local `secrets.yml`. 
> [!CAUTION]
> Never commit `secrets.yml` to version control. Use `secrets_example.yml` as a template.

---

## Security Measures

| Measure | Scope | Status |
| :--- | :--- | :--- |
| SSH Key Auth Only | All VMs | ✅ Automated |
| UFW Firewall | Wazuh Manager | ✅ Only essential ports open |
| Active Response | Wazuh Agent | ✅ Automatic IP blocking during attacks |
| TLS Encryption | Dashboard | ✅ Internal self-signed certs |

---

## Security Analysis

### Remaining Weaknesses
1.  **Self-signed Certificates:** The dashboard uses SSL but without a public CA, which is acceptable for lab environments.
2.  **Local Logging:** Logs are stored locally on the manager; a production environment would require off-site log shipping.

### Protection Layers
* **Network Segmentation:** Only the manager node exposes a web interface.
* **Automation:** Zero manual intervention reduces the risk of human-induced misconfiguration.
* **Visibility**: With centralized monitoring of /var/log/auth.log will ensure that all the login attempts are audited, both for failed and successful attempts. This creates the digital trail that is necessary for identifying unauthorized access attempts.

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
* Log ingestion: In the /var/log/auth.log there are authentication events visible in the Wazuh "Threat Hunting" dashboard.
* Manual alert trigger: The SSH attempts failed (e.g., using a non-existing user) has correctly triggered Rule ID 5710 in the manager.

---

## Design Choices and Justification

To ensure system stability across reboots, the implementation of idempotent Ansible playboks is in use.

* **EDR Selection (Wazuh):** Chosen for its robust ability to combine log analysis with active, real-time response.
* **Infrastructure as Code (IaC):** Allows for rapid tear-down and re-deployment, which promotes a "Green IT" approach by only keeping the lab active when needed.

---
**Created by:** Karin Ekenberg & Sandra Victorsson  
**Course:** Virtualization and Automation  
**Date:** 2026-04-29
