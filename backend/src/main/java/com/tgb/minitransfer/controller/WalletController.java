package com.tgb.minitransfer.controller;

import com.tgb.minitransfer.dto.BalanceResponse;
import com.tgb.minitransfer.service.WalletService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/wallet")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    @GetMapping("/balance")
    public BalanceResponse balance(Authentication authentication) {
        // The principal name is the authenticated user's id (set by JwtAuthenticationFilter).
        return walletService.getBalance(authentication.getName());
    }
}
