package com.tgb.minitransfer.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

/**
 * An immutable record of a money transfer between two users.
 * Email of each party is denormalized so history can be displayed without extra lookups.
 */
@Document(collection = "transactions")
public class Transaction {

    @Id
    private String id;

    @Indexed
    private String senderId;
    private String senderEmail;

    @Indexed
    private String recipientId;
    private String recipientEmail;

    /** Transferred amount, in FCFA. */
    private long amount;

    private TransactionStatus status;

    private Instant createdAt;

    public Transaction() {
    }

    public Transaction(String senderId, String senderEmail, String recipientId, String recipientEmail,
                       long amount, TransactionStatus status) {
        this.senderId = senderId;
        this.senderEmail = senderEmail;
        this.recipientId = recipientId;
        this.recipientEmail = recipientEmail;
        this.amount = amount;
        this.status = status;
        this.createdAt = Instant.now();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getSenderId() {
        return senderId;
    }

    public void setSenderId(String senderId) {
        this.senderId = senderId;
    }

    public String getSenderEmail() {
        return senderEmail;
    }

    public void setSenderEmail(String senderEmail) {
        this.senderEmail = senderEmail;
    }

    public String getRecipientId() {
        return recipientId;
    }

    public void setRecipientId(String recipientId) {
        this.recipientId = recipientId;
    }

    public String getRecipientEmail() {
        return recipientEmail;
    }

    public void setRecipientEmail(String recipientEmail) {
        this.recipientEmail = recipientEmail;
    }

    public long getAmount() {
        return amount;
    }

    public void setAmount(long amount) {
        this.amount = amount;
    }

    public TransactionStatus getStatus() {
        return status;
    }

    public void setStatus(TransactionStatus status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
