package com.elearning.adaptive.dto;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class SessionDTO {

    private UUID id;
    private Long enrollmentId;
    private Long courseId;
    private String courseTitle;
    private String studentName;
    private Double averageFrustrationScore;
    private String status;
    private OffsetDateTime startedAt;
    private OffsetDateTime endedAt;
    private Long durationSeconds;
}
