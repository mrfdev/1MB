#!/usr/bin/env bash
set -euo pipefail

# === CONFIG: set this to the absolute path of your server.properties ===
PROPS="/Users/floris/MinecraftServer/point9/server.properties"

# Check file exists
if [ ! -f "$PROPS" ]; then
  echo "Error: server.properties not found at: $PROPS" >&2
  exit 1
fi

# Helper: read key=value (ignores comments), strips CR
prop() {
  awk -F= -v key="$1" '
    $0 !~ /^[[:space:]]*#/ && $1==key {
      # print everything after the first '=' verbatim
      print substr($0, index($0,$2))
    }
  ' "$PROPS" | tr -d '\r'
}

SECRET="$(prop 'management-server-secret')"
PORT="$(prop 'management-server-port')"
HOST="$(prop 'management-server-host')"

# Defaults/validation
if [ -z "${SECRET:-}" ]; then
  echo "Error: management-server-secret not found in $PROPS" >&2
  exit 1
fi
: "${PORT:=25585}"
: "${HOST:=localhost}"

URL="wss://${HOST}:${PORT}"

# Subcommands: discover (default), status, players, stop
CMD="${1:-discover}"
case "$CMD" in
  discover)
    REQ='{"jsonrpc":"2.0","id":1,"method":"rpc.discover"}'
    ;;
  status)
    REQ='{"jsonrpc":"2.0","id":2,"method":"minecraft:status.get"}'
    ;;
  players)
    REQ='{"jsonrpc":"2.0","id":3,"method":"minecraft:players.list"}'
    ;;
  stop)
    # adjust method name if discover shows a different one
    REQ='{"jsonrpc":"2.0","id":99,"method":"minecraft:server.stop"}'
    ;;
  *)
    echo "Usage: $0 [discover|status|players|stop]" >&2
    exit 2
    ;;
esac

# Debug prints so we can see what’s going on
echo "Props: $PROPS"
echo "Host: $HOST"
echo "Port: $PORT"
echo "URL:  $URL"
echo "Secret: (length) ${#SECRET}"

# Send request (self-signed cert -> --insecure)
printf '%s\n' "$REQ" | websocat \
  --insecure \
  -H "Authorization: Bearer ${SECRET}" \
  -- \
  "$URL"
