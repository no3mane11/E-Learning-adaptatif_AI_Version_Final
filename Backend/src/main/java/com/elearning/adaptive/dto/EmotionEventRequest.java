package com.elearning.adaptive.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EmotionEventRequest {

    @NotNull
    private String timestamp;  // ISO8601 string sent by frontend

    @NotNull
    private Double frustrationScore;

    private Boolean faceDetected;

    private Double threshold;

    private String modelVersion;

    private Object meta;
}
