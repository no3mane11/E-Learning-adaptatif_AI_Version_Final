package com.elearning.adaptive.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateSessionStatusRequest {
    private String newStatus; // COMPLETED / ABANDONED
    private Integer durationSeconds;
}
