package com.tgb.minitransfer.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Type-safe binding of the {@code app.*} configuration namespace (see application.yml).
 */
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private final Jwt jwt = new Jwt();
    private final Wallet wallet = new Wallet();

    public Jwt getJwt() {
        return jwt;
    }

    public Wallet getWallet() {
        return wallet;
    }

    public static class Jwt {
        /** HMAC signing secret (>= 32 bytes for HS256). */
        private String secret;
        /** Token lifetime in milliseconds. */
        private long expirationMs = 86_400_000L;

        public String getSecret() {
            return secret;
        }

        public void setSecret(String secret) {
            this.secret = secret;
        }

        public long getExpirationMs() {
            return expirationMs;
        }

        public void setExpirationMs(long expirationMs) {
            this.expirationMs = expirationMs;
        }
    }

    public static class Wallet {
        /** Demo balance credited at registration, in FCFA. */
        private long initialBalance = 10_000L;

        public long getInitialBalance() {
            return initialBalance;
        }

        public void setInitialBalance(long initialBalance) {
            this.initialBalance = initialBalance;
        }
    }
}
