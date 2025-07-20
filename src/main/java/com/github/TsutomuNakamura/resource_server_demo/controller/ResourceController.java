package com.github.TsutomuNakamura.resource_server_demo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ResourceController {

    @GetMapping("/public/health")
    public ResponseEntity<Map<String, Object>> publicEndpoint() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "Public endpoint - no authentication required");
        response.put("timestamp", System.currentTimeMillis());
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/protected/user-info")
    public ResponseEntity<Map<String, Object>> protectedEndpoint(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "Protected endpoint - JWT token validated successfully");
        response.put("timestamp", System.currentTimeMillis());
        
        // Extract claims from JWT
        Map<String, Object> jwtInfo = new HashMap<>();
        jwtInfo.put("subject", jwt.getSubject());
        jwtInfo.put("issuer", jwt.getIssuer());
        jwtInfo.put("audience", jwt.getAudience());
        jwtInfo.put("issuedAt", jwt.getIssuedAt());
        jwtInfo.put("expiresAt", jwt.getExpiresAt());
        jwtInfo.put("scopes", jwt.getClaimAsStringList("scope"));
        jwtInfo.put("clientId", jwt.getClaimAsString("client_id"));
        
        response.put("jwt", jwtInfo);
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/protected/resource")
    public ResponseEntity<Map<String, Object>> protectedResource(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "Access granted to protected resource");
        response.put("timestamp", System.currentTimeMillis());
        response.put("resourceData", "This is sensitive data that requires authentication");
        response.put("clientId", jwt.getClaimAsString("client_id"));
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/hello")
    public ResponseEntity<Map<String, String>> hello(@AuthenticationPrincipal Jwt jwt) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello World");
        return ResponseEntity.ok(response);
    }
}
