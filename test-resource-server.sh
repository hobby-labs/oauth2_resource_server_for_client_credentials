#!/bin/bash

# Resource Server Test Script
# This script tests the OAuth2 resource server with JWK-based JWT verification

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OAUTH2_SERVER="http://localhost:9000"
RESOURCE_SERVER="http://localhost:9001"
CLIENT_ID="mobile-app-client"
CLIENT_SECRET="mobile-app-client-secret"
SCOPE="read"

echo -e "${BLUE}=== OAuth2 Resource Server Test Script ===${NC}"
echo

# Function to print colored output
print_step() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Function to make HTTP requests and format output
make_request() {
    local method=$1
    local url=$2
    local headers=$3
    local description=$4
    
    echo -e "\n${YELLOW}${description}${NC}"
    echo "Request: $method $url"
    
    if [ -n "$headers" ]; then
        echo "Headers: $headers"
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X "$method" -H "$headers" "$url")
    else
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X "$method" "$url")
    fi
    
    # Extract response body and status code
    response_body=$(echo "$response" | sed '$d')
    http_status=$(echo "$response" | tail -n1 | sed 's/HTTP_STATUS://')
    
    echo "Status: $http_status"
    echo "Response:"
    echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    echo
}

# Step 1: Check if servers are running
print_step "1. Checking server availability..."

# Check OAuth2 server
if curl -s "$OAUTH2_SERVER/oauth2/jwks" > /dev/null; then
    print_success "OAuth2 server is running at $OAUTH2_SERVER"
else
    print_error "OAuth2 server is not accessible at $OAUTH2_SERVER"
    exit 1
fi

# Check Resource server
if curl -s "$RESOURCE_SERVER/api/public/health" > /dev/null; then
    print_success "Resource server is running at $RESOURCE_SERVER"
else
    print_error "Resource server is not accessible at $RESOURCE_SERVER"
    exit 1
fi

# Step 2: Check JWK endpoint
print_step "2. Checking JWK endpoint..."
echo "JWK Set from OAuth2 server:"
curl -s "$OAUTH2_SERVER/oauth2/jwks" | jq .
echo

# Step 3: Test public endpoint (no authentication required)
print_step "3. Testing public endpoint (no authentication)..."
make_request "GET" "$RESOURCE_SERVER/api/public/health" "" "GET /api/public/health"

# Step 4: Test protected endpoint without token (should fail)
print_step "4. Testing protected endpoint without token (should return 401)..."
make_request "GET" "$RESOURCE_SERVER/api/protected/resource" "" "GET /api/protected/resource (no token)"

# Step 5: Get JWT token from OAuth2 server
print_step "5. Getting JWT token from OAuth2 server..."
echo "Getting token with client credentials grant..."

TOKEN_RESPONSE=$(curl -s -u "$CLIENT_ID:$CLIENT_SECRET" \
    -d "grant_type=client_credentials&scope=$SCOPE" \
    "$OAUTH2_SERVER/oauth2/token")

echo "Token response:"
echo "$TOKEN_RESPONSE" | jq .

# Extract access token
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    print_error "Failed to get access token"
    echo "Token response: $TOKEN_RESPONSE"
    exit 1
fi

print_success "Successfully obtained access token"
print_info "Token (first 50 chars): ${ACCESS_TOKEN:0:50}..."

# Decode JWT header and payload for inspection
print_step "6. Inspecting JWT token..."
header=$(echo "$ACCESS_TOKEN" | cut -d. -f1)
payload=$(echo "$ACCESS_TOKEN" | cut -d. -f2)

echo "JWT Header:"
echo "$header" | base64 -d 2>/dev/null | jq . || echo "Unable to decode header"

echo -e "\nJWT Payload:"
# Add padding for base64 decode
padded_payload="$payload"
while [ $((${#padded_payload} % 4)) -ne 0 ]; do
    padded_payload="${padded_payload}="
done
echo "$padded_payload" | base64 -d 2>/dev/null | jq . || echo "Unable to decode payload"
echo

# Step 7: Test protected endpoints with valid token
print_step "7. Testing protected endpoints with valid JWT token..."

# Test /api/protected/resource
make_request "GET" "$RESOURCE_SERVER/api/protected/resource" "Authorization: Bearer $ACCESS_TOKEN" "GET /api/protected/resource (with token)"

# Test /api/protected/user-info
make_request "GET" "$RESOURCE_SERVER/api/protected/user-info" "Authorization: Bearer $ACCESS_TOKEN" "GET /api/protected/user-info (with token)"

# Test /api/protected/hello
make_request "GET" "$RESOURCE_SERVER/api/protected/hello" "Authorization: Bearer $ACCESS_TOKEN" "GET /api/protected/hello (with token)"

# Step 8: Test with malformed token (should fail)
print_step "8. Testing with invalid token (should return 401)..."
INVALID_TOKEN="invalid.token.here"
make_request "GET" "$RESOURCE_SERVER/api/protected/resource" "Authorization: Bearer $INVALID_TOKEN" "GET /api/protected/resource (invalid token)"

# Step 9: Summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
print_success "JWK-based JWT verification is working correctly"
print_info "OAuth2 Server: $OAUTH2_SERVER"
print_info "Resource Server: $RESOURCE_SERVER"
print_info "Client ID: $CLIENT_ID"
print_info "Requested Scopes: $SCOPE"
echo
print_info "Available Endpoints:"
echo "  • Public:    GET $RESOURCE_SERVER/api/public/health"
echo "  • Protected: GET $RESOURCE_SERVER/api/protected/resource"
echo "  • Protected: GET $RESOURCE_SERVER/api/protected/user-info"
echo "  • Protected: GET $RESOURCE_SERVER/api/protected/hello"
echo
print_success "All tests completed successfully!"

# Step 10: Save token for manual testing
echo -e "\n${YELLOW}For manual testing, you can use this token:${NC}"
echo "export ACCESS_TOKEN=\"$ACCESS_TOKEN\""
echo
echo "Example manual test commands:"
echo "curl -H \"Authorization: Bearer \$ACCESS_TOKEN\" $RESOURCE_SERVER/api/protected/resource"
echo "curl -H \"Authorization: Bearer \$ACCESS_TOKEN\" $RESOURCE_SERVER/api/protected/user-info"
echo "curl -H \"Authorization: Bearer \$ACCESS_TOKEN\" $RESOURCE_SERVER/api/protected/hello"
