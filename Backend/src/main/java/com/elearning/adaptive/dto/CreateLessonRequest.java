package com.elearning.adaptive.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateLessonRequest {
    @NotBlank
    private String titre;

    // Use one of: THEORY, VIDEO, QUIZ, MIXED
    @NotBlank
    private String typeContenu;

    // ordre dans le cours (nullable)
    private Integer ordre;

    @NotNull
    private Long courseId;

    private String contenu;
}
