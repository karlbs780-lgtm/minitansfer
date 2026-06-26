package com.tgb.minitransfer.dto;

import com.tgb.minitransfer.model.Transaction;

import java.time.Instant;

public record TransactionDto(
        String id,
        TransactionDirection direction,
        String counterpartyEmail,
        long amount,
        String status,
        Instant createdAt
) {
    /** Projects a stored transaction from the point of view of the current user. */
    public static TransactionDto from(Transaction tx, String currentUserId) {
        boolean sent = tx.getSenderId().equals(currentUserId);
        return new TransactionDto(
                tx.getId(),
                sent ? TransactionDirection.SENT : TransactionDirection.RECEIVED,
                sent ? tx.getRecipientEmail() : tx.getSenderEmail(),
                tx.getAmount(),
                tx.getStatus().name(),
                tx.getCreatedAt()
        );
    }
}
