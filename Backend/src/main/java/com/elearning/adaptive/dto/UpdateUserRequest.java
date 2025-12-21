package com.elearning.adaptive.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateUserRequest {
    private String nom;

    @Email
    private String email;

    @Size(min = 8)
    private String password;

    private String role;
    private Boolean isActive;
}
