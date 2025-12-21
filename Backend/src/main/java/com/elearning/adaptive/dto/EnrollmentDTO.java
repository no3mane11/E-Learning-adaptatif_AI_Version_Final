package com.elearning.adaptive.dto;

import lombok.*;
import java.time.OffsetDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EnrollmentDTO {
    public Long id;
    public Long userId;
    public String userName;
    public Long courseId;
    public String courseTitle;
    public OffsetDateTime enrolledAt;
}
