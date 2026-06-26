package com.tgb.minitransfer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record TransferRequest(

        @NotBlank(message = "Le destinataire (email ou telephone) est obligatoire.")
        String recipient,

        @NotNull(message = "Le montant est obligatoire.")
        @Positive(message = "Le montant doit etre strictement positif.")
        Long amount
) {
}
