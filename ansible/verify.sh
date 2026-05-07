#!/bin/bash
# verify.sh — Automatic verification of the Wazuh EDR environment

MANAGER_IP="192.168.56.10"
WEB_IP="192.168.56.11"
DB_IP="192.168.56.12"
SSH_KEY="/home/vagrant/.ssh/id_ed25519"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"

PASS=0; FAIL=0

check() {
  local label="$1"; local cmd="$2"
  printf "Checking: %-50s" "$label"
  if eval "$cmd" &>/dev/null; then
    echo "OK"; ((PASS++))
  else
    echo "FAILED"; ((FAIL++))
  fi
}

echo "========================================"
echo " Wazuh EDR — Automatic Verification"
echo " $(date)"
echo "========================================"

echo ""
echo "--- Network verification ---"
check "Manager reachable (ping)"  "ping -c1 -W2 $MANAGER_IP"
check "Web-agent reachable (ping)" "ping -c1 -W2 $WEB_IP"
check "DB-agent reachable (ping)"  "ping -c1 -W2 $DB_IP"

echo ""
echo "--- Service verification (manager) ---"
check "wazuh-manager is running" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo systemctl is-active wazuh-manager'"
check "wazuh-indexer is running" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo systemctl is-active wazuh-indexer'"
check "wazuh-dashboard is running" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo systemctl is-active wazuh-dashboard'"

echo ""
echo "--- Agent verification (web-agent) ---"
check "wazuh-agent is running on web-agent" \
  "ssh $SSH_OPTS vagrant@$WEB_IP 'sudo systemctl is-active wazuh-agent'"
check "web-agent shows as Active in manager" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo /var/ossec/bin/agent_control -l | grep -i web-agent'"

echo ""
echo "--- Agent verification (db-agent) ---"
check "wazuh-agent is running on db-agent" \
  "ssh $SSH_OPTS vagrant@$DB_IP 'sudo systemctl is-active wazuh-agent'"
check "db-agent shows as Active in manager" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo /var/ossec/bin/agent_control -l | grep -i db-agent'"

echo ""
echo "--- Alert verification ---"
check "Wazuh alerts log exists and is non-empty" \
  "ssh $SSH_OPTS vagrant@$MANAGER_IP 'sudo test -s /var/ossec/logs/alerts/alerts.log'"

echo ""
echo "========================================"
echo " Result: $PASS checks OK, $FAIL failed"
echo "========================================"

if [ $FAIL -eq 0 ]; then
  echo " All checks passed — verification complete!"
  exit 0
else
  echo " $FAIL checks failed — check the output above"
  exit 1
fi