package com.elearning.adaptive.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Session {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "enrollment_id")
    private Enrollment enrollment;

    @Enumerated(EnumType.STRING)
    private SessionStatus status;

    private OffsetDateTime startedAt;
    private OffsetDateTime endedAt;

    private Long durationSeconds;

    @Column(name = "average_frustration_score")
    private Double averageFrustrationScore;
}
