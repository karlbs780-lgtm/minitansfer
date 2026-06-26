package com.tgb.minitransfer.dto;

import com.tgb.minitransfer.model.User;

public record UserDto(
        String id,
        String name,
        String email,
        String phone,
        long balance
) {
    public static UserDto from(User user) {
        return new UserDto(user.getId(), user.getName(), user.getEmail(), user.getPhone(), user.getBalance());
    }
}
