#!/bin/sh

set -e

# === CONFIGURATION ===
DDNS_HOSTNAME="your-ddns-hostname.xyz"
DISCORD_WEBHOOK_URL=""

LOG_FILE="/config/wg_confs/wireguard-healthcheck.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE" >&2
}

fail() {
  log "$1"
  exit 1
}

trap 'log "ERROR: 🔴 Healthcheck script failed with exit code $?, line $LINENO."' ERR

log "Starting WireGuard healthcheck..."

# Auto-detect WG config if not provided
CONFIG_PATH=$(find /config/wg_confs -maxdepth 1 -type f -name "*.conf" | head -n1)

if [ -z "$CONFIG_PATH" ]; then
  fail "[ERROR] 🔴 No WireGuard config file found in /config/wg_confs/"
fi

WG_INTERFACE=$(basename "$CONFIG_PATH" .conf)
#log "Using config: $CONFIG_PATH for interface: $WG_INTERFACE"

# Resolve expected real IP
REAL_IP=$(getent ahosts "$DDNS_HOSTNAME" | awk '{ print $1; exit }')

if [ -z "$REAL_IP" ]; then
  log "[ERROR] ⚠️ Could not resolve DDNS hostname: $DDNS_HOSTNAME"
fi

log "DDNS resolved IP: $REAL_IP"

# Get current VPN-routed public IP
VPN_IP=$(curl -s --interface "$WG_INTERFACE" https://api.ipify.org)

if [ -z "$VPN_IP" ]; then
  fail "[ERROR] 🔴 Failed to query public IP via interface $WG_INTERFACE"
fi

log "VPN-reported IP via $WG_INTERFACE: $VPN_IP"

# Compare and send alert if leaking
if [ "$REAL_IP" = "$VPN_IP" ]; then
  log "🔴 VPN leak detected! Sending Discord alert..."

  curl -s -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg msg ":rotating_light: VPN LEAK DETECTED! WireGuard container is exposing your real IP ($REAL_IP)" '{content: $msg}')"

  exit 1
else
  echo "✅ VPN leak test passed."
fi

# Extract DNS servers from config
DNS_LINE=$(grep -i '^DNS' "$CONFIG_PATH" | awk -F '= ' '{ print $2 }' | tr -d ' ')
DNS_SERVERS=$(echo "$DNS_LINE" | tr ',' ' ')

if [ -z "$DNS_SERVERS" ]; then
  fail "[ERROR] 🔴 No DNS servers found in config."
else
  DNS_SUCCESS=0
  for dns in $DNS_SERVERS; do
    #log "Pinging DNS server: $dns"
    if ping -c 1 -W 2 "$dns" >/dev/null 2>&1; then
      echo "✅ DNS server $dns is reachable."
      DNS_SUCCESS=1
      break
    else
      log "⚠️DNS server $dns is unreachable."
    fi
  done

  if [ "$DNS_SUCCESS" -eq 0 ]; then
    fail "[ERROR] 🔴 All DNS servers are unreachable. VPN tunnel may be broken."
  fi
fi

log "✅ All checks passed. Healthcheck successful."

# --- Trim log: Keep last 100 lines only ---

MAX_LINES=2000
TMP_LOG="${LOG_FILE}.tmp"

if [ -s "$LOG_FILE" ]; then
    if tail -n "$MAX_LINES" "$LOG_FILE" > "$TMP_LOG"; then
        if cat "$TMP_LOG" > "$LOG_FILE"; then
            echo "✅ INFO: Trimmed log successfully."
            rm -f "$TMP_LOG"
        else
            log "⚠️WARN: Could not overwrite original log file."
        fi
    else
        log "⚠️WARN: Failed to tail log file."
    fi
else
    log "⚠️INFO: Log file is empty or missing, skipping trim."
fi

exit 0
