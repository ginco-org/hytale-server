#!/bin/bash
set -e

# OAuth2 Device Code Flow for Hytale Server Authentication
# Based on: https://support.hytale.com/hc/en-us/articles/45328341414043

OAUTH_BASE_URL="https://oauth.accounts.hytale.com"
ACCOUNT_DATA_URL="https://account-data.hytale.com"
SESSION_URL="https://sessions.hytale.com"
CLIENT_ID="hytale-server"
SCOPES="openid offline auth:server"
TOKEN_CACHE="/data/.auth/tokens.json"

mkdir -p /data/.auth
chmod 700 /data/.auth

_create_game_session() {
  local access_token="$1"
  local profile_uuid="$2"

  SESSION_RESPONSE=$(curl -s -X POST "${SESSION_URL}/game-session/new" \
    -H "Authorization: Bearer ${access_token}" \
    -H "Content-Type: application/json" \
    -d "{\"uuid\": \"${profile_uuid}\"}")

  SESSION_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.sessionToken // empty')
  IDENTITY_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.identityToken // empty')

  if [ -n "$SESSION_TOKEN" ] && [ "$SESSION_TOKEN" != "null" ]; then
    return 0
  fi
  echo "Failed to create game session: $(echo "$SESSION_RESPONSE" | jq -c .)" >&2
  return 1
}

DO_DEVICE_FLOW=true

# Try cached refresh token first
if [ -f "$TOKEN_CACHE" ]; then
  echo "Found cached credentials, attempting token refresh..."

  # Disable set -e for the entire refresh block so any failure (network, parse
  # error, bad token) simply falls through to the interactive device flow.
  set +e

  CACHED_REFRESH_TOKEN=$(jq -r '.refresh_token // empty' "$TOKEN_CACHE" 2>/dev/null)
  CACHED_PROFILE_UUID=$(jq -r '.profile_uuid // empty' "$TOKEN_CACHE" 2>/dev/null)
  CACHED_PROFILE_USERNAME=$(jq -r '.profile_username // empty' "$TOKEN_CACHE" 2>/dev/null)

  if [ -n "$CACHED_REFRESH_TOKEN" ] && [ -n "$CACHED_PROFILE_UUID" ]; then
    REFRESH_RESPONSE=$(curl -s -X POST "${OAUTH_BASE_URL}/oauth2/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=${CLIENT_ID}" \
      -d "grant_type=refresh_token" \
      -d "refresh_token=${CACHED_REFRESH_TOKEN}" 2>/dev/null)

    REFRESHED_ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | jq -r '.access_token // empty' 2>/dev/null)
    REFRESHED_REFRESH_TOKEN=$(echo "$REFRESH_RESPONSE" | jq -r '.refresh_token // empty' 2>/dev/null)
    REFRESH_ERROR=$(echo "$REFRESH_RESPONSE" | jq -r '.error // empty' 2>/dev/null)

    if [ -n "$REFRESHED_ACCESS_TOKEN" ] && [ "$REFRESHED_ACCESS_TOKEN" != "null" ]; then
      echo "Token refresh successful. Creating game session for ${CACHED_PROFILE_USERNAME}..."

      if _create_game_session "$REFRESHED_ACCESS_TOKEN" "$CACHED_PROFILE_UUID"; then
        # Update cache with new refresh token (servers may rotate them)
        NEW_REFRESH_TOKEN="${REFRESHED_REFRESH_TOKEN:-$CACHED_REFRESH_TOKEN}"
        jq -n \
          --arg refresh_token "$NEW_REFRESH_TOKEN" \
          --arg profile_uuid "$CACHED_PROFILE_UUID" \
          --arg profile_username "$CACHED_PROFILE_USERNAME" \
          '{refresh_token: $refresh_token, profile_uuid: $profile_uuid, profile_username: $profile_username}' \
          > "$TOKEN_CACHE"
        chmod 600 "$TOKEN_CACHE"

        PROFILE_UUID="$CACHED_PROFILE_UUID"
        DO_DEVICE_FLOW=false
        echo "===================================================================="
        echo "Authentication successful (via cached credentials)!"
        echo "===================================================================="
        echo ""
      else
        echo "Game session creation failed after refresh, falling back to device flow..."
      fi
    else
      echo "Token refresh failed (${REFRESH_ERROR:-unknown error}), falling back to device flow..."
    fi
  fi

  set -e
fi

if [ "$DO_DEVICE_FLOW" = "true" ]; then
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
  ACCESS_TOKEN=""
  REFRESH_TOKEN=""

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

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')
    REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.refresh_token // empty')

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
  if ! _create_game_session "$ACCESS_TOKEN" "$PROFILE_UUID"; then
    exit 1
  fi
  echo "Game session created successfully!"
  echo ""

  # Persist credentials for future restarts
  if [ -n "$REFRESH_TOKEN" ] && [ "$REFRESH_TOKEN" != "null" ]; then
    jq -n \
      --arg refresh_token "$REFRESH_TOKEN" \
      --arg profile_uuid "$PROFILE_UUID" \
      --arg profile_username "$PROFILE_USERNAME" \
      '{refresh_token: $refresh_token, profile_uuid: $profile_uuid, profile_username: $profile_username}' \
      > "$TOKEN_CACHE"
    chmod 600 "$TOKEN_CACHE"
    echo "Credentials cached for future restarts."
  fi

  echo "===================================================================="
  echo "Authentication complete! Starting server..."
  echo "===================================================================="
  echo ""
fi

# Export tokens for the server to use
export HYTALE_SERVER_SESSION_TOKEN="$SESSION_TOKEN"
export HYTALE_SERVER_IDENTITY_TOKEN="$IDENTITY_TOKEN"
export OWNER_UUID="$PROFILE_UUID"
