package com.tgb.minitransfer.repository;

import com.tgb.minitransfer.model.Transaction;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface TransactionRepository extends MongoRepository<Transaction, String> {

    /** History of a user: transactions where they are sender or recipient, newest first. */
    List<Transaction> findBySenderIdOrRecipientIdOrderByCreatedAtDesc(String senderId, String recipientId);
}
