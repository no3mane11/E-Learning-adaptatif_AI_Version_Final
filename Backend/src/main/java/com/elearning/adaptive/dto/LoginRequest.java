package com.elearning.adaptive.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO reçu du front pour la connexion
 */
@Getter @Setter
@NoArgsConstructor
public class LoginRequest {
    private String email;
    private String password;
}
