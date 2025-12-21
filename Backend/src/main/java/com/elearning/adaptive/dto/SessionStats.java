package com.elearning.adaptive.dto;

import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SessionStats {
    private UUID sessionId;
    private int windowSeconds;        // fenêtre demandée (ex: 30)
    private OffsetDateTime windowStart;
    private OffsetDateTime windowEnd;

    private long count;              // nombre d'événements dans la fenêtre
    private double avgScore;         // moyenne des frustrationScore
    private double maxScore;
    private double minScore;
    private long frustrationCount;   // nombre d'événements au dessus du threshold (optionnel)
}
