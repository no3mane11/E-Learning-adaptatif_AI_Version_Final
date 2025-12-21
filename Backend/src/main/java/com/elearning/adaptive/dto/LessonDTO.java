package com.elearning.adaptive.dto;

import lombok.*;
import java.time.OffsetDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LessonDTO {
    public Long id;
    public String titre;
    public String typeContenu;
    public Integer ordre;
    public Long courseId;
    public String contenu;
    public String videoUrl;
    public String courseTitle;
    public OffsetDateTime createdAt; // changed
    public OffsetDateTime updatedAt; // changed
}
