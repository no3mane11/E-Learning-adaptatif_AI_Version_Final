package com.elearning.adaptive.dto;

import lombok.*;
import java.time.OffsetDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendationDTO {
    private Long id;
    private String content;
    private String triggerType;
    private OffsetDateTime createdAt;
    private boolean read;
}