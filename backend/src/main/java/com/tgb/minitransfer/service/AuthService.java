package com.tgb.minitransfer.service;

import com.tgb.minitransfer.config.AppProperties;
import com.tgb.minitransfer.dto.AuthResponse;
import com.tgb.minitransfer.dto.LoginRequest;
import com.tgb.minitransfer.dto.RegisterRequest;
import com.tgb.minitransfer.dto.UserDto;
import com.tgb.minitransfer.exception.ApiException;
import com.tgb.minitransfer.model.User;
import com.tgb.minitransfer.repository.UserRepository;
import com.tgb.minitransfer.security.JwtService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Registration and login. On registration the wallet is seeded with a demo balance.
 */
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AppProperties properties;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       JwtService jwtService, AppProperties properties) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.properties = properties;
    }

    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        String phone = request.phone().trim();

        if (userRepository.existsByEmail(email)) {
            throw ApiException.conflict("EMAIL_TAKEN", "Un compte existe deja avec cet email.");
        }
        if (userRepository.existsByPhone(phone)) {
            throw ApiException.conflict("PHONE_TAKEN", "Un compte existe deja avec ce numero de telephone.");
        }

        User user = new User(
                request.name().trim(),
                email,
                phone,
                passwordEncoder.encode(request.password()),
                properties.getWallet().getInitialBalance());

        try {
            user = userRepository.save(user);
        } catch (DuplicateKeyException ex) {
            // Safety net against a race between the existence checks above and the insert.
            throw ApiException.conflict("ACCOUNT_EXISTS", "Un compte existe deja avec cet email ou ce numero.");
        }

        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return AuthResponse.of(token, jwtService.getExpirationMs(), UserDto.from(user));
    }

    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.email());
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> ApiException.unauthorized("BAD_CREDENTIALS", "Email ou mot de passe incorrect."));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw ApiException.unauthorized("BAD_CREDENTIALS", "Email ou mot de passe incorrect.");
        }

        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return AuthResponse.of(token, jwtService.getExpirationMs(), UserDto.from(user));
    }

    private static String normalizeEmail(String email) {
        return email.trim().toLowerCase();
    }
}
