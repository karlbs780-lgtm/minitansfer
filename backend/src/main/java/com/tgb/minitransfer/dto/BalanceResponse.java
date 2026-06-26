package com.tgb.minitransfer.dto;

public record BalanceResponse(
        long balance,
        String currency
) {
    public static BalanceResponse of(long balance) {
        return new BalanceResponse(balance, "FCFA");
    }
}
