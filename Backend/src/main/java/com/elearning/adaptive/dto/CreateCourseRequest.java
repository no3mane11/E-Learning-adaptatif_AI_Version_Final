package com.elearning.adaptive.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateCourseRequest {
    @NotBlank
    @Size(max = 255)
    private String titre;

    private String description;
    // teacherId not required here if create course by authenticated teacher (we'll use auth principal)
    private Long teacherId; // optional: allow admin creating on behalf
}
