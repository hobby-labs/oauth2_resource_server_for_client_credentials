# JWK-based JWT Verification Implementation

## Overview

This implementation uses the **JSON Web Key (JWK) Set URI** approach for JWT verification, which is the recommended production approach for OAuth2 resource servers. Instead of hardcoding public keys, the resource server dynamically fetches public keys from the OAuth2 authorization server's JWK endpoint.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   OAuth2 Client │    │ OAuth2 Auth      │    │ Resource Server │
│                 │    │ Server           │    │ (This App)      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │ 1. Request Token      │                       │
         │──────────────────────▶│                       │
         │                       │                       │
         │ 2. Return JWT         │                       │
         │◀──────────────────────│                       │
         │                       │                       │
         │ 3. API Call with JWT  │                       │
         │───────────────────────────────────────────────▶│
         │                       │                       │
         │                       │ 4. Fetch JWK Set     │
         │                       │◀──────────────────────│
         │                       │                       │
         │                       │ 5. Return Public Keys│
         │                       │──────────────────────▶│
         │                       │                       │
         │ 6. Response (if valid)│                       │
         │◀───────────────────────────────────────────────│
```

## Key Features

### 1. **Automatic Key Discovery**
- Resource server automatically fetches public keys from `http://localhost:9000/oauth2/jwks`
- No manual key management required
- Supports multiple keys with different `kid` (Key ID) values

### 2. **Key Rotation Support**
- When OAuth2 server rotates keys, resource server automatically discovers new keys
- Old JWTs remain valid until expiration if the corresponding key is still in the JWK set
- Seamless transition during key rotation

### 3. **Multiple Key Support**
- Supports multiple active keys simultaneously
- JWT header `kid` field is used to select the appropriate verification key
- Current JWK set contains:
  - `ec-key-from-yaml`: Primary signing key
  - `ec-backup-2025`: Backup verification key

## Configuration

### application.yml
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          jwk-set-uri: http://localhost:9000/oauth2/jwks
```

### JwtConfig.java
```java
@Configuration
public class JwtConfig {
    
    @Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri}")
    private String jwkSetUri;

    @Bean
    public JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder.withJwkSetUri(jwkSetUri)
                .build();
    }
}
```

## JWK Endpoint Response

The OAuth2 server provides the following JWK set:

```json
{
  "keys": [
    {
      "kty": "EC",
      "use": "sig",
      "crv": "P-256",
      "kid": "ec-key-from-yaml",
      "key_ops": ["sign", "verify"],
      "x": "5gWFoky3mr51D0nA0S6WEuWsrrdHQTt0fBYNhoL533g",
      "y": "Cqyb9YxKvDpw3qE3NIBapYERcEvNnFfuUalhj1CfYY4",
      "alg": "ES256"
    },
    {
      "kty": "EC",
      "use": "sig",
      "crv": "P-256",
      "kid": "ec-backup-2025",
      "key_ops": ["verify"],
      "x": "fh1_E1hy157gxgaSvHFoFCJi3SguQr8OLeM0OQEyh7Y",
      "y": "e6ldN7We1sR5ckpIIfcJyWhdRbp3ZlsS4_TpsN8cwuk",
      "alg": "ES256"
    }
  ]
}
```

## JWT Verification Process

1. **JWT Reception**: Resource server receives JWT in `Authorization: Bearer` header
2. **JWK Set Fetching**: If not cached, fetch JWK set from configured URI
3. **Key Selection**: Extract `kid` from JWT header and find matching key in JWK set
4. **Signature Verification**: Verify JWT signature using the selected public key
5. **Claims Validation**: Validate standard claims (exp, iat, etc.)
6. **Authorization**: Process the validated JWT claims for authorization decisions

## Testing

### 1. Check JWK Endpoint
```bash
curl http://localhost:9000/oauth2/jwks | jq .
```

### 2. Test Protected Endpoint (without token)
```bash
curl -v http://localhost:9001/api/hello
# Expected: 401 Unauthorized
```

### 3. Test with Valid JWT
```bash
# Get JWT from OAuth2 server first, then:
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:9001/api/hello
# Expected: {"message": "Hello World"}
```

## Advantages over Static Key Approach

| Aspect | Static Key | JWK-based |
|--------|------------|-----------|
| **Key Rotation** | Manual update required | Automatic |
| **Multiple Keys** | Single key only | Multiple keys supported |
| **Security** | Key exposure risk | Dynamic key discovery |
| **Maintenance** | High | Minimal |
| **Production Ready** | Not recommended | Industry standard |
| **Scalability** | Limited | Excellent |

## Error Handling

The implementation automatically handles:
- **Invalid JWT signature**: Returns 401 with appropriate error
- **Expired JWT**: Returns 401 with expiration error
- **Missing kid**: Attempts verification with available keys
- **JWK endpoint unavailable**: Uses cached keys or returns 401
- **Unknown kid**: Returns 401 if no matching key found

## Security Considerations

1. **HTTPS in Production**: JWK Set URI should use HTTPS in production
2. **Caching**: JWK sets are cached to reduce network calls
3. **Key Validation**: All keys are validated before use
4. **Algorithm Restriction**: Only ES256 (ECDSA with P-256) is supported
5. **Network Security**: JWK endpoint should be secured appropriately

## Production Deployment

For production deployment:

1. Update `jwk-set-uri` to use HTTPS
2. Configure appropriate timeouts for JWK fetching
3. Set up monitoring for JWK endpoint availability
4. Implement proper logging for JWT validation failures
5. Consider JWK caching strategies for high-traffic scenarios

## Troubleshooting

### Common Issues

1. **JWK endpoint unreachable**: Check network connectivity
2. **Kid mismatch**: Ensure JWT header contains correct `kid`
3. **Algorithm mismatch**: Verify OAuth2 server uses ES256
4. **Clock skew**: Ensure system clocks are synchronized

### Debug Logs

Enable debug logging in `application.yml`:
```yaml
logging:
  level:
    org.springframework.security: DEBUG
    org.springframework.security.oauth2: DEBUG
```
