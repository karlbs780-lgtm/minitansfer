package com.tgb.minitransfer.service;

import com.mongodb.client.result.UpdateResult;
import com.tgb.minitransfer.dto.TransactionDto;
import com.tgb.minitransfer.dto.TransferRequest;
import com.tgb.minitransfer.dto.TransferResponse;
import com.tgb.minitransfer.exception.ApiException;
import com.tgb.minitransfer.model.Transaction;
import com.tgb.minitransfer.model.TransactionStatus;
import com.tgb.minitransfer.model.User;
import com.tgb.minitransfer.repository.TransactionRepository;
import com.tgb.minitransfer.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Executes money transfers while guaranteeing money is never created nor lost.
 *
 * <p>A standalone MongoDB (the default docker-compose setup) does not support multi-document
 * ACID transactions, so we rely on two <em>atomic single-document</em> updates plus a
 * compensating action:</p>
 * <ol>
 *   <li>Conditional debit of the sender ({@code balance >= amount} in the same atomic
 *       {@code $inc}). If it matches nothing, the sender lacked funds.</li>
 *   <li>Atomic credit of the recipient. If it fails, the sender is refunded (compensation),
 *       leaving balances untouched.</li>
 *   <li>Persist the transaction record.</li>
 * </ol>
 */
@Service
public class TransferService {

    private static final Logger log = LoggerFactory.getLogger(TransferService.class);

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final MongoTemplate mongoTemplate;

    public TransferService(UserRepository userRepository, TransactionRepository transactionRepository,
                           MongoTemplate mongoTemplate) {
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
        this.mongoTemplate = mongoTemplate;
    }

    public TransferResponse transfer(String senderId, TransferRequest request) {
        long amount = request.amount();
        // Defensive check (bean validation already enforces > 0 at the controller boundary).
        if (amount <= 0) {
            throw ApiException.badRequest("INVALID_AMOUNT", "Le montant doit etre strictement positif.");
        }

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "Utilisateur introuvable."));

        User recipient = findRecipient(request.recipient())
                .orElseThrow(() -> ApiException.notFound("RECIPIENT_NOT_FOUND", "Destinataire introuvable."));

        if (recipient.getId().equals(sender.getId())) {
            throw ApiException.badRequest("SELF_TRANSFER", "Impossible de transferer vers soi-meme.");
        }

        // 1) Atomic conditional debit: matches only if the sender still has enough funds.
        UpdateResult debit = mongoTemplate.updateFirst(
                Query.query(Criteria.where("id").is(sender.getId()).and("balance").gte(amount)),
                new Update().inc("balance", -amount),
                User.class);

        if (debit.getModifiedCount() == 0) {
            throw ApiException.badRequest("INSUFFICIENT_BALANCE", "Solde insuffisant pour effectuer ce transfert.");
        }

        // 2) Atomic credit of the recipient, with compensation on failure.
        try {
            UpdateResult credit = mongoTemplate.updateFirst(
                    Query.query(Criteria.where("id").is(recipient.getId())),
                    new Update().inc("balance", amount),
                    User.class);
            if (credit.getModifiedCount() == 0) {
                throw new IllegalStateException("Le destinataire n'existe plus pendant le credit.");
            }
        } catch (RuntimeException ex) {
            refund(sender.getId(), amount);
            log.error("Credit failed; sender {} refunded {} FCFA", sender.getId(), amount, ex);
            recordFailed(sender, recipient, amount);
            throw ApiException.conflict("TRANSFER_FAILED",
                    "Le transfert a echoue, aucune somme n'a ete debitee.");
        }

        // 3) Persist the completed transaction.
        Transaction tx = transactionRepository.save(new Transaction(
                sender.getId(), sender.getEmail(),
                recipient.getId(), recipient.getEmail(),
                amount, TransactionStatus.COMPLETED));

        long newBalance = userRepository.findById(sender.getId())
                .map(User::getBalance)
                .orElse(sender.getBalance() - amount);

        return TransferResponse.of(TransactionDto.from(tx, sender.getId()), newBalance);
    }

    /** Resolve a recipient by email (case-insensitive) or phone number. */
    private Optional<User> findRecipient(String recipientKey) {
        String key = recipientKey.trim();
        return userRepository.findByEmailOrPhone(key.toLowerCase(), key);
    }

    private void refund(String userId, long amount) {
        mongoTemplate.updateFirst(
                Query.query(Criteria.where("id").is(userId)),
                new Update().inc("balance", amount),
                User.class);
    }

    private void recordFailed(User sender, User recipient, long amount) {
        try {
            transactionRepository.save(new Transaction(
                    sender.getId(), sender.getEmail(),
                    recipient.getId(), recipient.getEmail(),
                    amount, TransactionStatus.FAILED));
        } catch (RuntimeException ignored) {
            // Never let bookkeeping mask the original failure.
        }
    }
}
