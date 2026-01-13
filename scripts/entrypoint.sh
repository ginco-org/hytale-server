#!/bin/bash
set -e

echo "===================================================================="
echo "Hytale Server Docker Container"
echo "===================================================================="

# Check EULA
if [ "$EULA" != "true" ]; then
  echo ""
  echo "ERROR: You must accept the Hytale EULA to run this server."
  echo "Set the environment variable EULA=true to accept."
  echo ""
  echo "By setting EULA=true you are indicating your agreement to Hytale's EULA."
  echo "Read the EULA at: https://www.hytale.com/eula"
  echo ""
  exit 1
fi

echo "EULA accepted."

# Fix permissions on /data directory
echo "Fixing permissions on /data..."
chown -R hytale:hytale /data 2>/dev/null || true
chown hytale:hytale /downloads 2>/dev/null || true

# Create necessary directories
mkdir -p /data/{logs,mods,universe,backups,.cache}
chown -R hytale:hytale /data/{logs,mods,universe,backups,.cache} 2>/dev/null || true

# Download server files if not present
if [ ! -f /data/HytaleServer.jar ]; then
  echo "Server files not found. Downloading..."
  /scripts/download-server.sh
else
  echo "Server files found."
fi

# Build JVM arguments
JVM_ARGS="-Xms${MEMORY} -Xmx${MEMORY} ${JVM_OPTS}"

# Add AOT cache if enabled
if [ "$ENABLE_AOT_CACHE" = "true" ] && [ -f /data/HytaleServer.aot ]; then
  JVM_ARGS="${JVM_ARGS} -XX:AOTCache=/data/HytaleServer.aot"
  echo "AOT cache enabled."
fi

# Build server arguments
SERVER_ARGS="--assets /data/Assets.zip"

# Add bind address
if [ -n "$BIND_ADDRESS" ]; then
  SERVER_ARGS="${SERVER_ARGS} --bind ${BIND_ADDRESS}"
fi

# Add authentication mode
SERVER_ARGS="${SERVER_ARGS} --auth-mode ${AUTH_MODE}"

# Add sentry option
if [ "$ENABLE_SENTRY" = "false" ]; then
  SERVER_ARGS="${SERVER_ARGS} --disable-sentry"
fi

# Add op permission
if [ "$ALLOW_OP" = "true" ]; then
  SERVER_ARGS="${SERVER_ARGS} --allow-op"
fi

# Add backup settings
if [ "$ENABLE_BACKUP" = "true" ]; then
  SERVER_ARGS="${SERVER_ARGS} --backup --backup-dir ${BACKUP_DIR} --backup-frequency ${BACKUP_FREQUENCY}"
fi

# Handle authentication
if [ "$AUTH_MODE" = "offline" ]; then
  echo "Running in offline mode (no authentication)."
elif [ -n "$HYTALE_SERVER_SESSION_TOKEN" ] && [ -n "$HYTALE_SERVER_IDENTITY_TOKEN" ]; then
  echo "Using provided authentication tokens."
else
  # No tokens provided - run device auth flow
  source /scripts/authenticate.sh
fi

# Add authentication arguments if we have tokens
if [ -n "$HYTALE_SERVER_SESSION_TOKEN" ] && [ -n "$HYTALE_SERVER_IDENTITY_TOKEN" ]; then
  SERVER_ARGS="${SERVER_ARGS} --session-token ${HYTALE_SERVER_SESSION_TOKEN}"
  SERVER_ARGS="${SERVER_ARGS} --identity-token ${HYTALE_SERVER_IDENTITY_TOKEN}"

  if [ -n "$OWNER_UUID" ]; then
    SERVER_ARGS="${SERVER_ARGS} --owner-uuid ${OWNER_UUID}"
  fi
fi

# Install mods if TYPE is set
if [ "$TYPE" != "vanilla" ]; then
  /scripts/install-mods.sh
fi

# Display configuration
echo ""
echo "===================================================================="
echo "Server Configuration:"
echo "===================================================================="
echo "Memory: ${MEMORY}"
echo "Bind Address: ${BIND_ADDRESS}"
echo "Auth Mode: ${AUTH_MODE}"
echo "Sentry: ${ENABLE_SENTRY}"
echo "Backups: ${ENABLE_BACKUP}"
echo "AOT Cache: ${ENABLE_AOT_CACHE}"
echo "===================================================================="
echo ""

# Change to data directory
cd /data

# Start the server
echo "Starting Hytale Server..."
echo "Command: java ${JVM_ARGS} -jar HytaleServer.jar ${SERVER_ARGS}"
echo ""

# Switch to hytale user and start server
exec gosu hytale java ${JVM_ARGS} -jar HytaleServer.jar ${SERVER_ARGS}
