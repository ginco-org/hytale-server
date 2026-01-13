#!/bin/bash
set -e

# OAuth2 Device Code Flow for Hytale Server Authentication
# Based on: https://support.hytale.com/hc/en-us/articles/45328341414043

OAUTH_BASE_URL="https://oauth.accounts.hytale.com"
ACCOUNT_DATA_URL="https://account-data.hytale.com"
SESSION_URL="https://sessions.hytale.com"
CLIENT_ID="hytale-server"
SCOPES="openid offline auth:server"

echo ""
echo "===================================================================="
echo "AUTHENTICATION REQUIRED"
echo "===================================================================="
echo "Starting OAuth2 Device Code Flow..."
echo ""

# Step 1: Request device code
echo "Requesting device authorization..."
DEVICE_RESPONSE=$(curl -s -X POST "${OAUTH_BASE_URL}/oauth2/device/auth" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${CLIENT_ID}" \
  -d "scope=${SCOPES}")

DEVICE_CODE=$(echo "$DEVICE_RESPONSE" | jq -r '.device_code')
USER_CODE=$(echo "$DEVICE_RESPONSE" | jq -r '.user_code')
VERIFICATION_URI=$(echo "$DEVICE_RESPONSE" | jq -r '.verification_uri')
VERIFICATION_URI_COMPLETE=$(echo "$DEVICE_RESPONSE" | jq -r '.verification_uri_complete')
EXPIRES_IN=$(echo "$DEVICE_RESPONSE" | jq -r '.expires_in')
INTERVAL=$(echo "$DEVICE_RESPONSE" | jq -r '.interval')

if [ "$DEVICE_CODE" = "null" ] || [ -z "$DEVICE_CODE" ]; then
  echo "ERROR: Failed to request device code"
  echo "$DEVICE_RESPONSE" | jq .
  exit 1
fi

# Step 2: Display instructions to user
echo "===================================================================="
echo "DEVICE AUTHORIZATION"
echo "===================================================================="
echo "Visit: ${VERIFICATION_URI_COMPLETE}"
echo ""
echo "Or go to: ${VERIFICATION_URI}"
echo "And enter code: ${USER_CODE}"
echo "===================================================================="
echo "Waiting for authorization (expires in ${EXPIRES_IN} seconds)..."
echo ""

# Step 3: Poll for token
POLL_INTERVAL=${INTERVAL:-5}
ELAPSED=0

while [ $ELAPSED -lt $EXPIRES_IN ]; do
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))

  TOKEN_RESPONSE=$(curl -s -X POST "${OAUTH_BASE_URL}/oauth2/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=${CLIENT_ID}" \
    -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
    -d "device_code=${DEVICE_CODE}")

  ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

  if [ "$ERROR" = "authorization_pending" ]; then
    echo "Still waiting for authorization... (${ELAPSED}/${EXPIRES_IN}s)"
    continue
  elif [ "$ERROR" = "slow_down" ]; then
    echo "Slowing down polling rate..."
    POLL_INTERVAL=$((POLL_INTERVAL + 5))
    continue
  elif [ -n "$ERROR" ]; then
    echo "ERROR: Authentication failed - $ERROR"
    echo "$TOKEN_RESPONSE" | jq .
    exit 1
  fi

  # Success! We have tokens
  ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

  if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    echo ""
    echo "===================================================================="
    echo "AUTHENTICATION SUCCESSFUL!"
    echo "===================================================================="
    break
  fi
done

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo ""
  echo "ERROR: Authentication timed out after ${EXPIRES_IN} seconds"
  exit 1
fi

# Step 4: Get available profiles
echo "Fetching game profiles..."
PROFILES_RESPONSE=$(curl -s -X GET "${ACCOUNT_DATA_URL}/my-account/get-profiles" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

PROFILE_UUID=$(echo "$PROFILES_RESPONSE" | jq -r '.profiles[0].uuid // empty')
PROFILE_USERNAME=$(echo "$PROFILES_RESPONSE" | jq -r '.profiles[0].username // empty')

if [ -z "$PROFILE_UUID" ] || [ "$PROFILE_UUID" = "null" ]; then
  echo "ERROR: No game profiles found"
  echo "$PROFILES_RESPONSE" | jq .
  exit 1
fi

echo "Found profile: ${PROFILE_USERNAME} (${PROFILE_UUID})"

# Step 5: Create game session
echo "Creating game session..."
SESSION_RESPONSE=$(curl -s -X POST "${SESSION_URL}/game-session/new" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"uuid\": \"${PROFILE_UUID}\"}")

SESSION_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.sessionToken // empty')
IDENTITY_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.identityToken // empty')

if [ -z "$SESSION_TOKEN" ] || [ "$SESSION_TOKEN" = "null" ]; then
  echo "ERROR: Failed to create game session"
  echo "$SESSION_RESPONSE" | jq .
  exit 1
fi

echo "Game session created successfully!"
echo ""

# Export tokens for the server to use
export HYTALE_SERVER_SESSION_TOKEN="$SESSION_TOKEN"
export HYTALE_SERVER_IDENTITY_TOKEN="$IDENTITY_TOKEN"
export OWNER_UUID="$PROFILE_UUID"

echo "===================================================================="
echo "Authentication complete! Starting server..."
echo "===================================================================="
echo ""
