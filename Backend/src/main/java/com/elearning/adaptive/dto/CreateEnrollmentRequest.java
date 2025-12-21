package com.elearning.adaptive.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateEnrollmentRequest {

    @NotNull
    private Long courseId;

    // actingUserId is extracted from authentication, so no userId here
}
