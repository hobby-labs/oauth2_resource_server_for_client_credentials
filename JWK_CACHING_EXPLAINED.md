# JWK Public Key Caching in Spring Boot OAuth2 Resource Server

## Quick Answer
**Yes, public keys from the JWK endpoint ARE cached by default for several minutes!**

## Default Caching Behavior

Spring Boot's `NimbusJwtDecoder` automatically caches JWK Sets with these default settings:

| Setting | Default Value | Description |
|---------|---------------|-------------|
| **Cache Duration** | **5 minutes** | How long keys are cached before refresh |
| **Cache Size** | 16 entries | Maximum number of cached JWK sets |
| **Refresh Strategy** | Automatic | Refreshes when cache expires or on validation failure |

## How Caching Works

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   First JWT     │    │ Resource Server  │    │ OAuth2 Server   │
│   Request       │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │ 1. JWT Verification   │                       │
         │──────────────────────▶│                       │
         │                       │ 2. Fetch JWK Set     │
         │                       │──────────────────────▶│ 
         │                       │                       │
         │                       │ 3. Return Public Keys│
         │                       │◀──────────────────────│
         │                       │ 4. Cache for 5min    │
         │                       │ ✓ Store in memory     │
         │ 5. Validation Success │                       │
         │◀──────────────────────│                       │

┌─────────────────┐    ┌──────────────────┐
│   Subsequent    │    │ Resource Server  │    ⚡ No network call!
│   JWT Requests  │    │                  │    🔄 Uses cached keys
│   (within 5min) │    │                  │
└─────────────────┘    └──────────────────┘
         │                       │
         │ JWT Verification      │
         │──────────────────────▶│ ✓ Use cached JWK
         │ Instant validation    │ ⚡ No latency
         │◀──────────────────────│
```

## Cache Benefits

### 🚀 **Performance**
- **No network latency** for subsequent JWT validations
- **Sub-millisecond** key lookup from memory cache
- **Reduced load** on OAuth2 server

### 🛡️ **Reliability**
- **Fallback** to cached keys if JWK endpoint is temporarily unavailable
- **Graceful degradation** during network issues
- **High availability** JWT validation

### 📊 **Efficiency**
- **Bandwidth savings** - JWK set fetched only every 5 minutes
- **CPU optimization** - No repeated JSON parsing
- **Memory efficient** - Only 16 JWK sets cached maximum

## Cache Refresh Triggers

The cache automatically refreshes in these scenarios:

1. **Time-based**: After 5 minutes (default TTL)
2. **Failure-based**: When JWT validation fails with "key not found"
3. **Manual**: Application restart clears cache

## Verification Test

Let's test the caching behavior:

```bash
# Test 1: First request (should fetch JWK set)
time curl -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:9001/api/protected/resource

# Test 2: Immediate second request (should use cache)
time curl -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:9001/api/protected/resource
```

## Configuration Options

While Spring Boot 3.x has simplified the caching API, you can still configure caching behavior:

### Option 1: Application Properties
```yaml
# application.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          jwk-set-uri: http://localhost:9000/oauth2/jwks
          # Note: Cache configuration in properties is limited in Spring Boot 3.x
```

### Option 2: Custom Configuration (Advanced)
If you need custom cache settings, you can create a custom `JwtDecoder`:

```java
@Bean
public JwtDecoder customJwtDecoder() {
    // For advanced caching control, you would need to implement
    // custom JWK source with your own cache configuration
    return NimbusJwtDecoder.withJwkSetUri(jwkSetUri)
            .jwsAlgorithm(SignatureAlgorithm.ES256)
            .build();
}
```

## Cache Monitoring

To monitor cache behavior, enable debug logging:

```yaml
# application.yml
logging:
  level:
    "[org.springframework.security.oauth2.jwt]": DEBUG
    "[com.nimbusds.jose.jwk.source]": DEBUG
```

## Production Considerations

### ✅ **Recommended Settings**
- **Default 5-minute cache** is optimal for most use cases
- **Higher cache duration** (10-15 min) for high-traffic applications
- **Lower cache duration** (1-2 min) for frequent key rotation scenarios

### ⚠️ **Trade-offs**

| Cache Duration | Pros | Cons |
|----------------|------|------|
| **Short (1-2 min)** | Quick key rotation support | More network calls |
| **Medium (5 min)** | ✅ **Balanced** - Default recommendation | Standard |
| **Long (15+ min)** | Fewer network calls | Slower key rotation response |

## Key Rotation Handling

The caching system elegantly handles key rotation:

1. **New keys added**: Cache refresh discovers new keys automatically
2. **Old keys removed**: Validation failures trigger cache refresh
3. **Gradual transition**: Multiple keys supported during rotation period

## Troubleshooting Cache Issues

### Problem: "Key not found" errors
**Solution**: Check if OAuth2 server's JWK endpoint is accessible and keys have correct `kid` values

### Problem: Stale key errors after rotation
**Solution**: Cache will auto-refresh on validation failure, or restart application

### Problem: Too many JWK endpoint calls
**Solution**: Verify cache is working with debug logging enabled

## Current Implementation Status

Your current configuration:
```java
NimbusJwtDecoder.withJwkSetUri(jwkSetUri)
    .jwsAlgorithm(SignatureAlgorithm.ES256)
    .build();
```

✅ **Caching is ENABLED by default**
- Cache duration: 5 minutes
- Automatic refresh: Yes
- Performance optimization: Active

## Summary

**YES, your public keys are cached for several minutes (5 minutes by default)!** 

This provides:
- ⚡ **Fast JWT validation** (no network calls for cached keys)
- 🛡️ **High reliability** (works during temporary JWK endpoint issues)  
- 🔄 **Automatic key rotation** support
- 📈 **Excellent performance** for production workloads

The default 5-minute cache is optimal for most OAuth2 implementations and provides the right balance between performance and security.
