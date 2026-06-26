package com.tgb.minitransfer.controller;

import com.tgb.minitransfer.dto.TransactionDto;
import com.tgb.minitransfer.dto.TransferRequest;
import com.tgb.minitransfer.dto.TransferResponse;
import com.tgb.minitransfer.service.TransactionService;
import com.tgb.minitransfer.service.TransferService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/transfers")
public class TransferController {

    private final TransferService transferService;
    private final TransactionService transactionService;

    public TransferController(TransferService transferService, TransactionService transactionService) {
        this.transferService = transferService;
        this.transactionService = transactionService;
    }

    @PostMapping
    public ResponseEntity<TransferResponse> transfer(Authentication authentication,
                                                     @Valid @RequestBody TransferRequest request) {
        TransferResponse response = transferService.transfer(authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/history")
    public List<TransactionDto> history(Authentication authentication) {
        return transactionService.history(authentication.getName());
    }
}
