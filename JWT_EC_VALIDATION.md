# OAuth2 Resource Server with EC Public Key Validation

This Spring Boot application demonstrates how to create a resource server that validates JWT access tokens using an Elliptic Curve (EC) public key stored in a local file.

## ✅ Implementation Summary

### **Requirements Met:**
1. ✅ **Endpoint requiring JWT access token**: `/api/hello`
2. ✅ **JWT signature validation using EC public key**: Uses key from `./src/main/resources/keys/ec-public-key_never-use-in-production.pem`
3. ✅ **Simple response for valid JWT**: Returns `{"message": "Hello World"}`

### **Key Components Created:**

#### 1. **Custom JWT Decoder (`JwtConfig.java`)**
- Loads EC public key from PEM file
- Creates custom JWT decoder that validates ES256 signatures
- Handles JWT parsing, signature verification, and expiration checking

#### 2. **Security Configuration (`SecurityConfig.java`)**
- Configures OAuth2 Resource Server with JWT support
- Sets up endpoint security rules:
  - `/api/hello` - Requires authentication
  - `/api/public/**` - No authentication required
  - `/api/protected/**` - Requires authentication

#### 3. **Protected Endpoint (`ResourceController.java`)**
```java
@GetMapping("/api/hello")
public ResponseEntity<Map<String, String>> hello(@AuthenticationPrincipal Jwt jwt) {
    Map<String, String> response = new HashMap<>();
    response.put("message", "Hello World");
    return ResponseEntity.ok(response);
}
```

## 🧪 Testing

### **Test with the provided JWT token:**

```bash
# Valid JWT request
curl -H "Authorization: Bearer eyJ4NWMiOlsiTUlJQ2RUQ0NBaHVnQXdJQkFnSUpBT0V4YW1wbGUxLi4uIiwiTUlJQ2RUQ0NBaHVnQXdJQkFnSUpBT0V4YW1wbGUyLi4uIl0sImtpZCI6ImVjLWtleS1mcm9tLWZpbGUiLCJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJteS1jbGllbnQiLCJhdWQiOiJteS1jbGllbnQiLCJ2ZXIiOiIxIiwibmJmIjoxNzUzMDEwOTI2LCJzY29wZSI6WyJyZWFkIl0sImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6OTAwMCIsImV4cCI6MTc4NDU0NjkyNiwiaWF0IjoxNzUzMDEwOTI2LCJjbGllbnRfbmFtZSI6IjUzMzZiOGQ4LWFmZDUtNDBmNy04ODJjLTJmZDQ5NzgxMGZiYSIsImp0aSI6ImZmN2IzNjFmLTgyY2EtNDkxNi05ZmJiLTJlMDQxMmM0NzY0NSIsImNsaWVudF9pZCI6Im15LWNsaWVudCJ9.q2raVXfIREEPbMve0KtrCgIU1GRNRa76LmG0TZARZm-Vq1bFKHRzhfLjsr4-G-R_ZvCuDZuY4V0GQOjg_zHpOw" \
  http://localhost:8080/api/hello

# Expected Response:
{"message":"Hello World"}
```

### **Test without token (should fail):**
```bash
curl http://localhost:8080/api/hello
# Returns: 401 Unauthorized
```

### **Run comprehensive tests:**
```bash
./test-ec-jwt-endpoints.sh
```

## 🔧 Technical Details

### **JWT Validation Process:**
1. **Parse JWT**: Extract header and payload from token
2. **Verify Signature**: Use EC public key to validate ES256 signature
3. **Check Expiration**: Ensure token hasn't expired
4. **Extract Claims**: Convert to Spring Security JWT object

### **Public Key Location:**
- File: `./src/main/resources/keys/ec-public-key_never-use-in-production.pem`
- Algorithm: ES256 (ECDSA using P-256 curve)
- Key ID: `ec-key-from-file`

### **Dependencies Added:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

## 🚀 Running the Application

```bash
# Start the application
./mvnw spring-boot:run

# The application runs on http://localhost:8080
```

## 📚 Available Endpoints

| Endpoint | Authentication | Description |
|----------|---------------|-------------|
| `GET /api/hello` | Required | Returns `{"message": "Hello World"}` |
| `GET /api/public/health` | None | Public health check |
| `GET /api/protected/user-info` | Required | JWT token details |
| `GET /api/protected/resource` | Required | Protected resource data |

## 🔐 Security Features

- ✅ JWT signature validation using EC public key
- ✅ Token expiration checking
- ✅ Proper error handling for invalid tokens
- ✅ Secure endpoint configuration
- ✅ Support for ES256 algorithm (ECDSA with P-256)

This implementation provides a complete, working example of JWT validation using local EC public keys, perfect for scenarios where you need to validate tokens signed by a specific authority without relying on external JWK endpoints.
