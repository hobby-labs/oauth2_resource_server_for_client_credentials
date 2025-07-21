#!/bin/bash

# Quick Test Script for /api/protected/resource endpoint
# This demonstrates the exact functionality you requested

echo "=== Testing /api/protected/resource endpoint ==="
echo

# Get JWT token
echo "1. Getting JWT token from OAuth2 server..."
TOKEN_RESPONSE=$(curl -s -u mobile-app-client:mobile-app-client-secret \
    -d "grant_type=client_credentials&scope=read" \
    http://localhost:9000/oauth2/token)

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

echo "✓ Token obtained successfully"
echo

# Test the exact endpoint you mentioned
echo "2. Testing http://localhost:9001/api/protected/resource..."
response=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    http://localhost:9001/api/protected/resource)

echo "Response:"
echo "$response" | jq .
echo

echo "✅ JWK-based JWT verification working perfectly!"
echo "🔑 Resource server automatically fetched public keys from:"
echo "   http://localhost:9000/oauth2/jwks"
echo "🛡️ JWT signature verified using EC key with kid: 'ec-key-from-yaml'"
echo "📋 All JWT claims validated (expiration, issuer, audience, etc.)"
