package com.github.TsutomuNakamura.resource_server_demo.config;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSVerifier;
import com.nimbusds.jose.crypto.ECDSAVerifier;
import com.nimbusds.jwt.SignedJWT;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.oauth2.jwt.*;

import java.io.InputStream;
import java.security.KeyFactory;
import java.security.interfaces.ECPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.text.ParseException;
import java.time.Instant;
import java.util.Base64;
import java.util.Collections;

@Configuration
public class JwtConfig {

    @Bean
    public JwtDecoder jwtDecoder() {
        try {
            // Load the public key from the PEM file
            ClassPathResource resource = new ClassPathResource("keys/ec-public-key_never-use-in-production.pem");
            
            try (InputStream inputStream = resource.getInputStream()) {
                String pemContent = new String(inputStream.readAllBytes());
                
                // Remove PEM headers and newlines
                String publicKeyPEM = pemContent
                    .replace("-----BEGIN PUBLIC KEY-----", "")
                    .replace("-----END PUBLIC KEY-----", "")
                    .replaceAll("\\s+", "");
                
                // Decode the Base64 encoded key
                byte[] keyBytes = Base64.getDecoder().decode(publicKeyPEM);
                
                // Create the public key
                X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
                KeyFactory keyFactory = KeyFactory.getInstance("EC");
                ECPublicKey publicKey = (ECPublicKey) keyFactory.generatePublic(keySpec);
                
                // Create custom JWT decoder
                return new CustomECJwtDecoder(publicKey);
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to load JWT public key", e);
        }
    }
    
    private static class CustomECJwtDecoder implements JwtDecoder {
        private final ECPublicKey publicKey;
        
        public CustomECJwtDecoder(ECPublicKey publicKey) {
            this.publicKey = publicKey;
        }
        
        @Override
        public Jwt decode(String token) throws JwtException {
            try {
                // Parse the signed JWT
                SignedJWT signedJWT = SignedJWT.parse(token);
                
                // Create ECDSA verifier
                JWSVerifier verifier = new ECDSAVerifier(publicKey);
                
                // Verify the signature
                if (!signedJWT.verify(verifier)) {
                    throw new JwtValidationException("Invalid JWT signature", Collections.emptyList());
                }
                
                // Check expiration
                Instant expiry = signedJWT.getJWTClaimsSet().getExpirationTime().toInstant();
                if (Instant.now().isAfter(expiry)) {
                    throw new JwtValidationException("JWT token has expired", Collections.emptyList());
                }
                
                // Convert to Spring Security JWT
                return createJwt(signedJWT);
                
            } catch (ParseException | JOSEException e) {
                throw new JwtException("Failed to decode JWT", e);
            }
        }
        
        private Jwt createJwt(SignedJWT signedJWT) throws ParseException {
            return new Jwt(
                signedJWT.serialize(),
                signedJWT.getJWTClaimsSet().getIssueTime().toInstant(),
                signedJWT.getJWTClaimsSet().getExpirationTime().toInstant(),
                signedJWT.getHeader().toJSONObject(),
                signedJWT.getJWTClaimsSet().getClaims()
            );
        }
    }
}
