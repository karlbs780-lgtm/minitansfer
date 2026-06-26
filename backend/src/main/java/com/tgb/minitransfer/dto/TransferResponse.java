package com.tgb.minitransfer.dto;

public record TransferResponse(
        String message,
        TransactionDto transaction,
        long newBalance,
        String currency
) {
    public static TransferResponse of(TransactionDto transaction, long newBalance) {
        return new TransferResponse("Transfert effectue avec succes.", transaction, newBalance, "FCFA");
    }
}
