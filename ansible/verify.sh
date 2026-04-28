#!/bin/bash
# verify.sh — Automatic verification of the Wazuh EDR environment
# ⚠️  Replace the IP addresses below with your actual Tailscale IPs!

MANAGER_IP="100.x.x.x"   # Tailscale IP for the manager VM
AGENT_IP="100.x.x.x"     # Tailscale IP for the server1 VM
SSH_KEY="~/.vagrant.d/insecure_private_key"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"

PASS=0; FAIL=0

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
echo " Wazuh EDR — Automatic Verification"
echo " $(date)"
echo "========================================"

echo ""
echo "--- Network verification ---"
check "Tailscale reaches manager VM" "tailscale ping $MANAGER_IP"
check "Tailscale reaches client VM"  "tailscale ping $AGENT_IP"

echo ""
echo "--- Service verification (manager) ---"
check "wazuh-manager is running" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo systemctl is-active wazuh-manager'"
check "wazuh-indexer is running" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo systemctl is-active wazuh-indexer'"
check "wazuh-dashboard is running" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo systemctl is-active wazuh-dashboard'"

echo ""
echo "--- Agent verification ---"
check "wazuh-agent is running on client VM" \
  "ssh $SSH_OPTS vagrant@$AGENT_IP 'sudo systemctl is-active wazuh-agent'"
check "Agent shows as Active in manager" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo /var/ossec/bin/agent_control -l | grep -i active'"

echo ""
echo "--- Alert verification ---"
check "Wazuh alerts exist in log file" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo test -s /var/ossec/logs/alerts/alerts.log'"

echo ""
echo "========================================"
echo " Result: $PASS checks OK, $FAIL failed"
echo "========================================"

if [ $FAIL -eq 0 ]; then
  echo " ✅ All checks passed — verification complete!"
  exit 0
else
  echo " ❌ $FAIL checks failed — see troubleshooting section"
  exit 1
fi
