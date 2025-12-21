package com.elearning.adaptive.dto;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.*;

import java.time.OffsetDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RecommendationTriggerDTO {
    private Long id;
    private String sessionId; // session UUID as string
    private OffsetDateTime createdAt;
    private String type;
    private JsonNode details; // object JSON
}
