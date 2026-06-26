package com.tgb.minitransfer.service;

import com.mongodb.client.result.UpdateResult;
import com.tgb.minitransfer.dto.TransactionDirection;
import com.tgb.minitransfer.dto.TransferRequest;
import com.tgb.minitransfer.dto.TransferResponse;
import com.tgb.minitransfer.exception.ApiException;
import com.tgb.minitransfer.model.Transaction;
import com.tgb.minitransfer.model.User;
import com.tgb.minitransfer.repository.TransactionRepository;
import com.tgb.minitransfer.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.catchThrowableOfType;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransferServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private MongoTemplate mongoTemplate;

    @InjectMocks
    private TransferService transferService;

    private User sender;
    private User recipient;

    @BeforeEach
    void setUp() {
        sender = new User("Alice", "alice@mail.com", "+237600000001", "hash", 10_000L);
        sender.setId("sender-1");
        recipient = new User("Bob", "bob@mail.com", "+237600000002", "hash", 5_000L);
        recipient.setId("recipient-1");
    }

    @Test
    void rejectsNonPositiveAmount() {
        ApiException ex = catchThrowableOfType(
                () -> transferService.transfer("sender-1", new TransferRequest("bob@mail.com", 0L)),
                ApiException.class);

        assertThat(ex.getCode()).isEqualTo("INVALID_AMOUNT");
        verify(transactionRepository, never()).save(any());
    }

    @Test
    void rejectsUnknownRecipient() {
        when(userRepository.findById("sender-1")).thenReturn(Optional.of(sender));
        when(userRepository.findByEmailOrPhone(anyString(), anyString())).thenReturn(Optional.empty());

        ApiException ex = catchThrowableOfType(
                () -> transferService.transfer("sender-1", new TransferRequest("ghost@mail.com", 1_000L)),
                ApiException.class);

        assertThat(ex.getCode()).isEqualTo("RECIPIENT_NOT_FOUND");
    }

    @Test
    void rejectsSelfTransfer() {
        when(userRepository.findById("sender-1")).thenReturn(Optional.of(sender));
        when(userRepository.findByEmailOrPhone(anyString(), anyString())).thenReturn(Optional.of(sender));

        ApiException ex = catchThrowableOfType(
                () -> transferService.transfer("sender-1", new TransferRequest("alice@mail.com", 1_000L)),
                ApiException.class);

        assertThat(ex.getCode()).isEqualTo("SELF_TRANSFER");
        verify(transactionRepository, never()).save(any());
    }

    @Test
    void rejectsInsufficientBalance() {
        when(userRepository.findById("sender-1")).thenReturn(Optional.of(sender));
        when(userRepository.findByEmailOrPhone(anyString(), anyString())).thenReturn(Optional.of(recipient));
        // The conditional debit matches nothing -> not enough funds.
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(User.class)))
                .thenReturn(UpdateResult.acknowledged(0L, 0L, null));

        ApiException ex = catchThrowableOfType(
                () -> transferService.transfer("sender-1", new TransferRequest("bob@mail.com", 999_999L)),
                ApiException.class);

        assertThat(ex.getCode()).isEqualTo("INSUFFICIENT_BALANCE");
        verify(transactionRepository, never()).save(any());
    }

    @Test
    void completesValidTransfer() {
        User senderAfter = new User("Alice", "alice@mail.com", "+237600000001", "hash", 8_000L);
        senderAfter.setId("sender-1");

        when(userRepository.findById("sender-1"))
                .thenReturn(Optional.of(sender))        // initial lookup
                .thenReturn(Optional.of(senderAfter));  // re-read for the new balance
        when(userRepository.findByEmailOrPhone(anyString(), anyString())).thenReturn(Optional.of(recipient));
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(User.class)))
                .thenReturn(UpdateResult.acknowledged(1L, 1L, null));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(invocation -> {
            Transaction tx = invocation.getArgument(0);
            tx.setId("tx-1");
            return tx;
        });

        TransferResponse response = transferService.transfer("sender-1", new TransferRequest("bob@mail.com", 2_000L));

        assertThat(response.transaction().status()).isEqualTo("COMPLETED");
        assertThat(response.transaction().direction()).isEqualTo(TransactionDirection.SENT);
        assertThat(response.transaction().amount()).isEqualTo(2_000L);
        assertThat(response.transaction().counterpartyEmail()).isEqualTo("bob@mail.com");
        assertThat(response.newBalance()).isEqualTo(8_000L);
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void refundsSenderWhenCreditFails() {
        when(userRepository.findById("sender-1")).thenReturn(Optional.of(sender));
        when(userRepository.findByEmailOrPhone(anyString(), anyString())).thenReturn(Optional.of(recipient));
        // Debit succeeds, credit matches nothing -> compensation must refund the sender.
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(User.class)))
                .thenReturn(UpdateResult.acknowledged(1L, 1L, null))   // debit
                .thenReturn(UpdateResult.acknowledged(0L, 0L, null))   // credit (fails)
                .thenReturn(UpdateResult.acknowledged(1L, 1L, null));  // refund

        assertThatThrownBy(() -> transferService.transfer("sender-1", new TransferRequest("bob@mail.com", 2_000L)))
                .isInstanceOf(ApiException.class)
                .hasFieldOrPropertyWithValue("code", "TRANSFER_FAILED");

        // Three updateFirst calls: debit + failed credit + compensating refund.
        verify(mongoTemplate, org.mockito.Mockito.times(3))
                .updateFirst(any(Query.class), any(Update.class), eq(User.class));
    }
}
