package com.tgb.minitransfer.service;

import com.tgb.minitransfer.dto.TransactionDto;
import com.tgb.minitransfer.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;

    public TransactionService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    /** Transactions for a user (sent + received), newest first, projected to their point of view. */
    public List<TransactionDto> history(String userId) {
        return transactionRepository
                .findBySenderIdOrRecipientIdOrderByCreatedAtDesc(userId, userId)
                .stream()
                .map(tx -> TransactionDto.from(tx, userId))
                .toList();
    }
}
