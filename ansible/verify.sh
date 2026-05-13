#!/bin/bash
# verify.sh — Automatic verification for local Wazuh environment

AGENT_IP="192.168.56.11"
DB_IP="192.168.56.12"

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
echo " Wazuh Lab — Automatic Verification"
echo " $(date)"
echo "========================================"

echo ""
echo "--- Network Connectivity ---"
check "Connectivity to Agent VM ($AGENT_IP)" "ping -c 1 $AGENT_IP"
check "Connectivity to DB VM ($DB_IP)"       "ping -c 1 $DB_IP"

echo ""
echo "--- Local Service Status (Manager) ---"
check "wazuh-manager service is active"  "systemctl is-active wazuh-manager"
check "wazuh-indexer service is active"  "systemctl is-active wazuh-indexer"
check "wazuh-dashboard service is active" "systemctl is-active wazuh-dashboard"

echo ""
echo "--- Remote Agent Status ---"
check "wazuh-agent is active on web-agent" "ssh vagrant@$AGENT_IP 'systemctl is-active wazuh-agent'"
check "wazuh-agent is active on db-agent"  "ssh vagrant@$DB_IP 'systemctl is-active wazuh-agent'"
check "web-agent registered as Active in Manager" "sudo /var/ossec/bin/agent_control -l | grep -iE 'web-agent.*(active|connected)'"
check "db-agent registered as Active in Manager"  "sudo /var/ossec/bin/agent_control -l | grep -iE 'db-agent.*(active|connected)'"

echo ""
echo "--- Log Integrity ---"
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