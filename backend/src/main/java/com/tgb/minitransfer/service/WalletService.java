package com.tgb.minitransfer.service;

import com.tgb.minitransfer.dto.BalanceResponse;
import com.tgb.minitransfer.exception.ApiException;
import com.tgb.minitransfer.model.User;
import com.tgb.minitransfer.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class WalletService {

    private final UserRepository userRepository;

    public WalletService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public BalanceResponse getBalance(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "Utilisateur introuvable."));
        return BalanceResponse.of(user.getBalance());
    }
}
