package com.elearning.adaptive.dto;

import jakarta.validation.constraints.NotEmpty;
import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BulkEmotionEventRequest {

    @NotEmpty
    private List<EmotionEventRequest> events;

    private String clientBatchId;
}
