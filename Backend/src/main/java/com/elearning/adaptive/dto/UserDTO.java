package com.elearning.adaptive.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;

@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDTO {
    private Long id;
    private String nom;
    private String email;
    private String role;               // use enum name (STUDENT/TEACHER)
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private Boolean isActive;
}
