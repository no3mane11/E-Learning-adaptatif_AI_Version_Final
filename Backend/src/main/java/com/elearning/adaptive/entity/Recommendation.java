package com.elearning.adaptive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "recommendations")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Recommendation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "lesson_id")
    private Long lessonId;

    @Column(nullable = false)
    private OffsetDateTime createdAt;

    @Column(nullable = false)
    private String triggerType; // ex: "FRUSTRATION_HIGH"

    @Column(columnDefinition = "TEXT")
    private String content; // Le message d'aide généré

    @Column(name = "is_read")
    private boolean read = false;
}