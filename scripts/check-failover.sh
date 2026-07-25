#!/usr/bin/env bash
set -euo pipefail

URL=${1:?Usage: check-failover.sh http://app.example.com [timeout-seconds]}
TIMEOUT=${2:-600}
START=$(date +%s)
DEADLINE=$((START + TIMEOUT))

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  BODY=$(curl -sS --max-time 10 "$URL/health" || true)
  printf '%s %s\n' "$(date -u +%FT%TZ)" "$BODY"
  if echo "$BODY" | jq -e '.environment == "standby" and .status == "healthy"' >/dev/null 2>&1; then
    echo "RTO_SECONDS=$(($(date +%s) - START))"
    exit 0
  fi
  sleep 10
done

exit 1
