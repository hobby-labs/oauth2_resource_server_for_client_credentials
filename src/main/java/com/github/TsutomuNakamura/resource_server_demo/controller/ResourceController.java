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

    @GetMapping("/protected/resource")
    public ResponseEntity<Map<String, Object>> protectedResource(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "Access granted to protected resource");
        response.put("timestamp", System.currentTimeMillis());
        response.put("resourceData", "This is sensitive data that requires authentication");

        response.put("clientId", jwt.getClaimAsString("client_id"));
        response.put("subject", jwt.getSubject());
        response.put("issuer", jwt.getIssuer());
        response.put("audience", jwt.getAudience());
        response.put("issuedAt", jwt.getIssuedAt());
        response.put("expiresAt", jwt.getExpiresAt());
        response.put("scopes", jwt.getClaimAsStringList("scope"));
        
        return ResponseEntity.ok(response);
    }
}
