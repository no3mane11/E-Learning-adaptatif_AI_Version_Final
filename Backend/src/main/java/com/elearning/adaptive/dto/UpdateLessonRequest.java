package com.elearning.adaptive.dto;

import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateLessonRequest {
    @Size(max = 255)
    private String titre;

    private String typeContenu;
    private Integer ordre;
}
