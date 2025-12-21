package com.elearning.adaptive.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO reçu du front pour l'inscription
 * NOTE: backend doit valider/ignorer le role fourni par le client et par défaut attribuer STUDENT
 */
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterRequest {
    private String nom;
    private String email;
    private String password;
    private String role; // optional: better to ignore / validate server-side
}
