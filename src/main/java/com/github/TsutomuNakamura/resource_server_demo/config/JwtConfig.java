package com.github.TsutomuNakamura.resource_server_demo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

@Configuration
public class JwtConfig {

    @Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri}")
    private String jwkSetUri;

    @Bean
    public JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder.withJwkSetUri(jwkSetUri)
                .jwsAlgorithm(org.springframework.security.oauth2.jose.jws.SignatureAlgorithm.ES256)
                // Note: JWK Set caching is enabled by default with 5-minute cache duration
                // The cache refreshes automatically when keys expire or change
                .build();
    }
}
