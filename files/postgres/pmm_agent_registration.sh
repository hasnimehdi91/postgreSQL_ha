#!/bin/bash

# ------------------------------------------------------------------------------
# Environment Validation
# ------------------------------------------------------------------------------

# Exit the script with an error if any of the required environment variables
# are unset or empty. These are necessary for registering the service with PMM.

: "${SERVICE_NAME:?Environment variable SERVICE_NAME is required}"
: "${PMM_SERVER_URL:?Environment variable PMM_SERVER_URL is required}"
: "${PMM_USERNAME:?Environment variable PMM_USERNAME is required}"
: "${PMM_PASSWORD:?Environment variable PMM_PASSWORD is required}"

# ------------------------------------------------------------------------------
# Timeout Configuration
# ------------------------------------------------------------------------------

TIMEOUT=120     # Total time (in seconds) to wait for the port to open
INTERVAL=2      # Interval (in seconds) between checks
ELAPSED=0       # Tracks the total time waited
PORT="${PORT:-8008}" # Patroni /metrics port
SERVER_PORT="${SERVER_PORT:-8443}" # PMM server port

echo "[INFO] Waiting for port $PORT to become available (timeout: $TIMEOUT seconds)..."

# ------------------------------------------------------------------------------
# Wait for the Port to Become Available
# ------------------------------------------------------------------------------

# Loop until the specified port on localhost is open or the timeout is reached
while ! nc -z localhost "$PORT"; do
    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))

    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "[ERROR] Timeout reached. Port $PORT did not open within $TIMEOUT seconds."
        exit 1
    fi
done

# ------------------------------------------------------------------------------
# Register the External Service with PMM
# ------------------------------------------------------------------------------

echo "[INFO] Port $PORT is now open. Registering service '$SERVICE_NAME' with PMM..."

sleep 20

# Step 1: Setup (foreground)
pmm-agent setup \
    --config-file=/pmm-agent/pmm-agent.yaml \
    --id="${SERVICE_NAME}" \
    --server-address="${PMM_SERVER_URL}:${SERVER_PORT}" \
    --server-username="${PMM_USERNAME}" \
    --server-password="${PMM_PASSWORD}" \
    --server-insecure-tls \
    container container

# Step 2: Start agent in background
pmm-agent --config-file=/pmm-agent/pmm-agent.yaml &

# Step 3: Register the external service
pmm-admin add external \
    --listen-port="${PORT}" \
    --service-name="${SERVICE_NAME}" \
    --server-insecure-tls \
    --server-url="https://${PMM_USERNAME}:${PMM_PASSWORD}@${PMM_SERVER_URL}:${SERVER_PORT}"

