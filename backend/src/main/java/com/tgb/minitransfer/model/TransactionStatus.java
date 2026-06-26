package com.tgb.minitransfer.model;

public enum TransactionStatus {
    /** Funds were debited from the sender and credited to the recipient. */
    COMPLETED,
    /** The transfer was attempted but could not be completed. */
    FAILED
}
