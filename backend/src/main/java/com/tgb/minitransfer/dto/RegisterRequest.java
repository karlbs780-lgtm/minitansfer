package com.tgb.minitransfer.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(

        @NotBlank(message = "Le nom est obligatoire.")
        @Size(max = 100)
        String name,

        @NotBlank(message = "L'email est obligatoire.")
        @Email(message = "L'email n'est pas valide.")
        String email,

        @NotBlank(message = "Le numero de telephone est obligatoire.")
        @Pattern(regexp = "^\\+?[0-9 ]{6,20}$", message = "Le numero de telephone n'est pas valide.")
        String phone,

        @NotBlank(message = "Le mot de passe est obligatoire.")
        @Size(min = 6, max = 100, message = "Le mot de passe doit contenir au moins 6 caracteres.")
        String password
) {
}
