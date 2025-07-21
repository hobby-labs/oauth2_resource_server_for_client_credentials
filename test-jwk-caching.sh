#!/bin/bash

# Test script to demonstrate JWK caching behavior
echo "=== JWK Caching Demonstration ==="
echo

# Get access token
echo "Getting access token..."
ACCESS_TOKEN=$(curl -s -u mobile-app-client:mobile-app-client-secret \
    -d "grant_type=client_credentials&scope=read" \
    http://localhost:9000/oauth2/token | jq -r '.access_token')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to get access token"
    exit 1
fi

echo "✅ Access token obtained"
echo

# Function to test JWT validation performance
test_jwt_validation() {
    local test_name=$1
    echo "🔍 $test_name"
    start_time=$(date +%s%N)
    
    response=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        http://localhost:9001/api/protected/resource)
    
    end_time=$(date +%s%N)
    duration_ms=$(( (end_time - start_time) / 1000000 ))
    
    if echo "$response" | jq -e '.status == "OK"' > /dev/null 2>&1; then
        echo "   ✅ Success (${duration_ms}ms)"
    else
        echo "   ❌ Failed (${duration_ms}ms)"
    fi
    
    return $duration_ms
}

# Test 1: First request (should fetch JWK set)
echo "📋 Test 1: First JWT validation (may trigger JWK fetch)"
test_jwt_validation "First request"
first_duration=$?
echo

# Test 2: Immediate second request (should use cache)
echo "📋 Test 2: Second JWT validation (should use JWK cache)"
test_jwt_validation "Second request (immediate)"
second_duration=$?
echo

# Test 3: Third request (should definitely use cache)
echo "📋 Test 3: Third JWT validation (cached)"
test_jwt_validation "Third request"
third_duration=$?
echo

# Analysis
echo "=== Performance Analysis ==="
echo "First request:  ${first_duration}ms"
echo "Second request: ${second_duration}ms"
echo "Third request:  ${third_duration}ms"
echo

if [ $second_duration -lt $first_duration ] && [ $third_duration -lt $first_duration ]; then
    echo "✅ CACHING WORKING: Subsequent requests are faster!"
    echo "   This indicates JWK keys are being cached in memory."
else
    echo "ℹ️  Cache performance varies - network and system load affect timing."
fi

echo
echo "🔑 JWK Caching Facts:"
echo "   • Default cache duration: 5 minutes"
echo "   • Keys cached in memory for fast lookup"
echo "   • Automatic refresh when cache expires"
echo "   • No network calls needed for cached keys"
echo "   • Cache refreshes on validation failures"
echo
echo "📊 To see detailed caching logs, enable debug logging:"
echo "   logging.level.[org.springframework.security.oauth2.jwt]: DEBUG"
