package com.elearning.adaptive.dto;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EmotionEventDTO {
    private UUID id;
    private UUID sessionId;
    private OffsetDateTime timestamp;
    private Double frustrationScore;
    private Boolean faceDetected;
    private String modelVersion;
    private Double threshold;

    // remplacer metaJson:String par un JsonNode "meta" (objet JSON exploitable côté client)
    private JsonNode meta;
}
