package com.tgb.minitransfer.security;

import com.tgb.minitransfer.config.AppProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        AppProperties properties = new AppProperties();
        properties.getJwt().setSecret("test-secret-test-secret-test-secret-0123456789");
        properties.getJwt().setExpirationMs(3_600_000L);
        jwtService = new JwtService(properties);
    }

    @Test
    void generatesTokenAndExtractsUserId() {
        String token = jwtService.generateToken("user-123", "user@mail.com");

        assertThat(token).isNotBlank();
        assertThat(jwtService.extractUserId(token)).isEqualTo("user-123");
    }

    @Test
    void rejectsTamperedToken() {
        String token = jwtService.generateToken("user-123", "user@mail.com");

        assertThatThrownBy(() -> jwtService.extractUserId(token + "tampered"))
                .isInstanceOf(Exception.class);
    }
}
