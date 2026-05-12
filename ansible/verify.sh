#!/bin/bash
# verify.sh — Automatic verification for local Wazuh environment

# Configuration: Replace with the actual IP from your hosts.ini
AGENT_IP="192.168.56.11" 

PASS=0; FAIL=0

# Helper function to check status and print formatted output
check() {
  local label="$1"; local cmd="$2"
  printf "Checking: %-45s" "$label"
  if eval "$cmd" &>/dev/null; then
    echo "✅ OK"; ((PASS++))
  else
    echo "❌ FAILED"; ((FAIL++))
  fi
}

echo "========================================"
echo " Wazuh Lab — Automatic Verification"
echo " $(date)"
echo "========================================"

echo ""
echo "--- Network Connectivity ---"
# Verify that the Manager can reach the Agent VM
check "Connectivity to Agent VM ($AGENT_IP)" "ping -c 1 $AGENT_IP"

echo ""
echo "--- Local Service Status (Manager) ---"
# Ensure the core Wazuh stack is active on the local machine
check "wazuh-manager service is active" "systemctl is-active wazuh-manager"
check "wazuh-indexer service is active" "systemctl is-active wazuh-indexer"
check "wazuh-dashboard service is active" "systemctl is-active wazuh-dashboard"

echo ""
echo "--- Remote Agent Status ---"
# Check if the agent service is running on the target VM via SSH
check "wazuh-agent is active on Agent VM" "ssh vagrant@$AGENT_IP 'systemctl is-active wazuh-agent'"
# Verify if the manager recognizes the agent as 'Active'
check "Agent is registered as 'Active' in Manager" "sudo /var/ossec/bin/agent_control -l | grep -i active"

echo ""
echo "--- Log Integrity ---"
# Check if the alert log file exists and contains data (proof of detection)
check "Wazuh alert log exists and is not empty" "sudo test -s /var/ossec/logs/alerts/alerts.log"

echo ""
echo "========================================"
echo " Results: $PASS passed, $FAIL failed"
echo "========================================"

if [ $FAIL -eq 0 ]; then
  echo " ✅ Verification successful — Environment is ready!"
  exit 0
else
  echo " ❌ Issues detected — Please troubleshoot before the demo."
  exit 1
fi