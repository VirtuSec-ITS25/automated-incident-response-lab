# Automated Incident Response Lab

> An automated infrastructure for distributed security monitoring. This project deploys a Wazuh EDR environment across multiple nodes using Ansible and Vagrant, focusing on active threat detection, real-time file integrity monitoring, and automated incident response.

---

## 📋 Table of Contents
1. Architecture
2. Environments and IP Addresses
3. Directory Structure
4. Components
5. Prerequisites
6. Getting Started
7. Security Measures
8. Security Analysis
9. Detection Rules
10. Verification
11. Design Choices and Justification
12. Future Improvements and Refactoring

---

## Architecture

<img width="1263" height="697" alt="Architecture diagram" src="https://github.com/user-attachments/assets/b0bf18ef-9185-4a25-aaf6-b0cf3d94b2af" />

---

## Environments and IP Addresses

| VM Name | Role | IP Address | Port Forwarding | Description |
| :--- | :--- | :--- | :--- | :--- |
| `wazuh-manager` | Central Server | `192.168.56.10` | `:443 → host:8443` | Indexer, Server, Dashboard & Ansible Control Node. |
| `web-agent` | Monitored System | `192.168.56.11` | — | Attack Target (Simulated Web Server). |
| `db-agent` | Monitored System | `192.168.56.12` | — | Attack Target (Simulated Database). |

---

## Directory Structure

```
automated-incident-response-lab/
├── Vagrantfile
├── manager_key.pub
├── .gitignore
└── ansible/
    ├── ansible.cfg
    ├── site.yml
    ├── verify.sh
    ├── inventory/
    │   └── hosts.ini
    ├── files/
    │   └── wordlist.txt
    ├── playbooks/
    │   ├── setup_target.yml
    │   ├── run_attack.yml
    │   ├── fim_test.yml
    │   └── cleanup.yml
    └── roles/
        ├── attack_target/
        │   ├── handlers/
        │   │   └── main.yml
        │   └── tasks/
        │       └── main.yml
        ├── attacker/
        │   ├── tasks/
        │   │   └── main.yml
        │   └── templates/
        │       └── run_attack.sh.j2
        └── wazuh_agent/
            ├── defaults/
            │   └── main.yml
            ├── handlers/
            │   └── main.yml
            ├── tasks/
            │   └── main.yml
            └── templates/
                └── ossec.conf.j2
```

---

## Components

### Vagrantfile
Defines the three virtual machines in VirtualBox on a private network. The manager generates an ed25519 SSH key pair during provisioning and shares the public key via the `/vagrant` synced folder so agents can add it to `authorized_keys`.

### ansible.cfg
Minimal configuration that disables host key checking for the lab environment and sets the default inventory path.

### inventory/hosts.ini
Groups the servers into functional units (`wazuh_manager`, `wazuh_agents`) and defines shared connection variables using the Vagrant SSH key.

### site.yml
Orchestrates deployment in three sequential plays:

1. Scans agent SSH host keys into `known_hosts` on the manager
2. Downloads and runs the Wazuh all-in-one installer on the manager
3. Installs and configures the Wazuh agent role on all nodes in `wazuh_agents`

### roles/wazuh_agent
Installs the Wazuh agent using the official apt repository with a properly dearmored GPG key. Deploys `ossec.conf` from a Jinja2 template that enables real-time FIM on `/etc`, `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, and monitors `/var/log/auth.log` for authentication events.

### roles/attack_target
Creates a `testuser` account with a weak password and enables SSH password authentication to make the brute force simulation possible. Reversed entirely by `cleanup.yml`.

### roles/attacker
Deploys the Hydra attack tool and generates a dynamic attack script from `run_attack.sh.j2`. The template renders the target IP at runtime from the Ansible inventory.

### playbooks/setup_target.yml
Applies the `attack_target` role to all `wazuh_agents` to prepare them for the simulation.

### playbooks/run_attack.yml
Runs Hydra from the manager against `web-agent` using a wordlist of common passwords targeting `testuser` over SSH.

### playbooks/fim_test.yml
Automatically creates, modifies, and deletes a test file in `/etc` on `db-agent`, waits for Wazuh to detect each change via inotify, then verifies that FIM alerts were generated on the manager.

### playbooks/cleanup.yml
Removes `testuser`, restores SSH password authentication to disabled, and clears any iptables DROP rules added by Wazuh active response.

### verify.sh
Runs 10 automated checks covering network connectivity to both agents, all three Wazuh services, agent service status on both VMs, agent registration in the manager, and alert log integrity.

---

## Prerequisites

**Software:**
- VirtualBox (7.x+)
- Vagrant (2.x+)
- Ansible (installed locally or via control node)

**Hardware Requirements:**
- Minimum **16 GB RAM** — the manager stack is resource-intensive.
- **30-40 GB** free disk space — recommended on external storage (e.g. `E:/Lab_Storage`).

---

## Getting Started

```bash
# 1. Clone the repository
git clone <url>
cd automated-incident-response-lab

# 2. Start and provision all VMs
vagrant up

# 3. SSH into the manager
vagrant ssh wazuh-manager
cd /vagrant/ansible

# 4. Install Wazuh manager and agents
ansible-playbook --inventory inventory/hosts.ini site.yml

# 5. Get Wazuh Dashboard admin password
sudo tar -O -xvf /tmp/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt

# 6. Prepare attack targets
ansible-playbook --inventory inventory/hosts.ini playbooks/setup_target.yml

# 7. Run SSH brute force attack
ansible-playbook --inventory inventory/hosts.ini playbooks/run_attack.yml

# 8. Run FIM test
ansible-playbook --inventory inventory/hosts.ini playbooks/fim_test.yml

# 9. Verify the environment
bash verify.sh

# 10. Clean up
ansible-playbook --inventory inventory/hosts.ini playbooks/cleanup.yml

# 11. Destroy VMs (from host machine)
exit
vagrant destroy -f
```

---

## Security Measures

| Measure | Scope | Status |
| :--- | :--- | :--- |
| SSH Key Authentication | All agents | ✅ Automated via Vagrantfile |
| UFW Firewall | All agents | ✅ Only SSH port open |
| Active Response | Wazuh Agent | ✅ Automatic IP blocking during attacks |
| TLS Encryption | Dashboard | ✅ Internal self-signed certificates |
| Real-time FIM | db-agent | ✅ Inotify-based, sub-second detection |
| Centralized Log Monitoring | All agents | ✅ auth.log ingested by Wazuh manager |

---

## Security Analysis

### Intentional Weaknesses

- **SSH password authentication enabled on agents:** `setup_target.yml` enables `PasswordAuthentication yes` in `sshd_config` to make the brute force simulation possible. This is explicitly reversed by `cleanup.yml`. In a production environment, password authentication should always be disabled.
- **Weak password for testuser:** The `testuser` account is created with a password included in the Hydra wordlist to guarantee a successful brute force hit. This is intentional for demonstration purposes.
- **Attack launched from the manager:** Hydra runs on `wazuh-manager` using `connection: local`. This means the security monitoring node is also the attacker, which would never be acceptable in production. It is done here to keep the VM count at three and stay within the RAM budget.

### Remaining Weaknesses

- **Self-signed certificates:** The dashboard uses TLS but without a public CA, which is acceptable for lab environments but would require a valid certificate in production.
- **Local log storage:** Logs are stored locally on the manager. A production environment would require off-site log shipping to prevent log tampering after a compromise.

### Protection Layers

- **Network Segmentation:** Only the manager node exposes a web interface; agents communicate inbound only to the manager.
- **Automation:** Zero manual intervention reduces the risk of human-induced misconfiguration.
- **Visibility:** Centralized monitoring of `/var/log/auth.log` ensures all login attempts are audited — both failed and successful — creating the digital trail necessary for identifying unauthorized access attempts.

---

## Detection Rules

| Rule ID | Description | Level | Triggered by |
| :--- | :--- | :--- | :--- |
| 5760 | sshd: authentication failed | 5 | Each failed SSH login |
| 5763 | sshd: brute force attempt | 10 | Multiple failures from same IP |
| 5758 | Maximum authentication attempts exceeded | 8 | SSH max retries hit |
| 40111 | Multiple authentication failures | 10 | Aggregated failures |
| 2501 | User authentication failure | 5 | PAM auth failure |
| 2502 | User missed password more than once | 10 | Repeated PAM failures |
| 550 | Integrity checksum changed | 7 | File modified (FIM) |
| 553 | File deleted | 7 | File removed (FIM) |
| 554 | File added | 5 | File created (FIM) |

---

## Verification

The Wazuh Dashboard is accessible at `https://192.168.56.10` (or `https://localhost:8443` if using port forwarding). Log in using the admin credentials found in `wazuh-passwords.txt` after deployment.

To verify that the lab is functioning correctly, run the verification script from inside the manager:

```bash
bash verify.sh
```

Expected output — 10/10 checks passed:

```
--- Network Connectivity ---
Checking: Connectivity to Agent VM (192.168.56.11)     ✅ OK
Checking: Connectivity to DB VM (192.168.56.12)        ✅ OK
--- Local Service Status (Manager) ---
Checking: wazuh-manager service is active              ✅ OK
Checking: wazuh-indexer service is active              ✅ OK
Checking: wazuh-dashboard service is active            ✅ OK
--- Remote Agent Status ---
Checking: wazuh-agent is active on web-agent           ✅ OK
Checking: wazuh-agent is active on db-agent            ✅ OK
Checking: web-agent registered as Active in Manager    ✅ OK
Checking: db-agent registered as Active in Manager     ✅ OK
--- Log Integrity ---
Checking: Wazuh alert log exists and is not empty      ✅ OK
Results: 10 passed, 0 failed
```

---

## Design Choices and Justification

**Why use the Wazuh all-in-one installer instead of custom roles?**
The all-in-one installer handles the interdependencies between the Wazuh manager, indexer (OpenSearch), and dashboard — including TLS certificate generation and internal authentication. Reproducing this with custom Ansible roles would require significant additional complexity. For a lab environment the official installer is the most reliable and tested approach.

**Why deploy ossec.conf from a template instead of using blockinfile?**
The initial approach used `blockinfile` to insert only the `<localfile>` block into the installer-generated `ossec.conf`. This was replaced with a full Jinja2 template to support real-time FIM configuration (`realtime="yes"`), which requires modifying the `<syscheck>` block. A full template gives complete control over the agent configuration and is more maintainable.

**Why use a shell task for the GPG key instead of get_url?**
`get_url` downloads the GPG key in its raw armored format, which Ubuntu 22.04's apt cannot use directly with `signed-by`. Piping the download through `gpg --dearmor` produces the binary keyring format that `signed-by` requires. The `creates:` argument makes the task idempotent.

**Why hard-code the manager IP in cleanup.yml?**
`cleanup.yml` runs only against `wazuh_agents` and does not include `wazuh_manager` as a play host. Ansible does not populate `hostvars` for hosts outside the current play, so `hostvars['wazuh_manager']` is undefined at runtime. Using the static IP `192.168.56.10` is the correct solution for a fixed lab network.

**Why use Infrastructure as Code (IaC)?**
Vagrant and Ansible allow rapid tear-down and re-deployment of the entire lab environment. This promotes a "Green IT" approach by only keeping the lab active when needed, and ensures the environment is always in a known, reproducible state.

**Why use EDR (Wazuh) over a traditional SIEM?**
Wazuh was chosen for its ability to combine log analysis with active, real-time response — including automatic IP blocking via iptables when brute force thresholds are exceeded. A traditional SIEM would detect the attack but not respond to it automatically.

---

## Future Improvements and Refactoring
- **Strict Network Baseline:** Refactor the `roles/attack_target` to set up a global UFW `policy: deny` for any incoming traffic. This requires firewall rules that whitelists the specific ports of `1514` and `1515` (TCP/UDP) for the Wazuh Agent, making the log shipping uninterrupted and secure.
- **Code Modularization:** To enhance the mantainability and scalabilty, split playbook tasks into independent, specialized Ansible roles.

---

**Created by:** Karin Ekenberg & Sandra Victorsson  
**Course:** Virtualization and Automation  
**Date:** 2026-05-18
