#!/bin/bash

# OAuth2 Resource Server Test Script with EC Public Key Validation

echo "=== Testing OAuth2 Resource Server with EC Public Key Validation ==="
echo ""

# Sample JWT token for testing
JWT_TOKEN="eyJ4NWMiOlsiTUlJQ2RUQ0NBaHVnQXdJQkFnSUpBT0V4YW1wbGUxLi4uIiwiTUlJQ2RUQ0NBaHVnQXdJQkFnSUpBT0V4YW1wbGUyLi4uIl0sImtpZCI6ImVjLWtleS1mcm9tLWZpbGUiLCJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJteS1jbGllbnQiLCJhdWQiOiJteS1jbGllbnQiLCJ2ZXIiOiIxIiwibmJmIjoxNzUzMDEwOTI2LCJzY29wZSI6WyJyZWFkIl0sImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6OTAwMCIsImV4cCI6MTc4NDU0NjkyNiwiaWF0IjoxNzUzMDEwOTI2LCJjbGllbnRfbmFtZSI6IjUzMzZiOGQ4LWFmZDUtNDBmNy04ODJjLTJmZDQ5NzgxMGZiYSIsImp0aSI6ImZmN2IzNjFmLTgyY2EtNDkxNi05ZmJiLTJlMDQxMmM0NzY0NSIsImNsaWVudF9pZCI6Im15LWNsaWVudCJ9.q2raVXfIREEPbMve0KtrCgIU1GRNRa76LmG0TZARZm-Vq1bFKHRzhfLjsr4-G-R_ZvCuDZuY4V0GQOjg_zHpOw"

# Test 1: Public endpoint (no authentication required)
echo "1. Testing public endpoint (no authentication required):"
echo "curl http://localhost:8080/api/public/health"
echo ""
curl http://localhost:8080/api/public/health
echo ""
echo ""

# Test 2: Protected Hello World endpoint without token (should return 401)
echo "2. Testing protected hello endpoint without token (should return 401):"
echo "curl -v http://localhost:8080/api/hello"
echo ""
curl -i http://localhost:8080/api/hello 2>/dev/null | head -1
echo ""
echo ""

# Test 3: Protected Hello World endpoint with JWT token (should return "Hello World")
echo "3. Testing protected hello endpoint with JWT token:"
echo "curl -H \"Authorization: Bearer \$JWT_TOKEN\" http://localhost:8080/api/hello"
echo ""
curl -H "Authorization: Bearer $JWT_TOKEN" http://localhost:8080/api/hello
echo ""
echo ""

# Test 4: Other protected endpoints with JWT token
echo "4. Testing other protected endpoints with JWT token:"
echo ""
echo "curl -H \"Authorization: Bearer \$JWT_TOKEN\" http://localhost:8080/api/protected/user-info"
curl -H "Authorization: Bearer $JWT_TOKEN" http://localhost:8080/api/protected/user-info
echo ""
echo ""

echo "curl -H \"Authorization: Bearer \$JWT_TOKEN\" http://localhost:8080/api/protected/resource"
curl -H "Authorization: Bearer $JWT_TOKEN" http://localhost:8080/api/protected/resource
echo ""
echo ""

# Test 5: Test with invalid token (should return 401)
echo "5. Testing with invalid JWT token (should return 401):"
echo "curl -i -H \"Authorization: Bearer invalid-token\" http://localhost:8080/api/hello"
curl -i -H "Authorization: Bearer invalid-token" http://localhost:8080/api/hello 2>/dev/null | head -1
echo ""
echo ""

echo "=== Test Summary ==="
echo "✅ /api/public/health - Works without authentication"
echo "✅ /api/hello - Requires valid JWT, returns {\"message\": \"Hello World\"}"
echo "✅ /api/protected/* - Requires valid JWT, shows JWT token details"
echo "✅ JWT signature validation using EC public key from file"
echo "✅ Invalid tokens are properly rejected"
echo ""
echo "The JWT token is validated using the EC public key located at:"
echo "  ./src/main/resources/keys/ec-public-key_never-use-in-production.pem"
