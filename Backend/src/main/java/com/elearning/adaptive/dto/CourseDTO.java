package com.elearning.adaptive.dto;

import lombok.*;
import java.time.OffsetDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CourseDTO {
    public Long id;
    public String titre;
    public String description;
    public Long teacherId;
    public String teacherName;
    public OffsetDateTime createdAt; // changed
    public OffsetDateTime updatedAt; // changed
}
