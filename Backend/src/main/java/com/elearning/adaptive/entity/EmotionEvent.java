package com.elearning.adaptive.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "emotion_events",
        indexes = {
                @Index(name = "idx_emotion_session_ts", columnList = "session_id, event_timestamp")
        })
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EmotionEvent {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private Session session;

    @Column(name = "event_timestamp", nullable = false)
    private OffsetDateTime timestamp;

    @Column(nullable = false)
    private Double frustrationScore;

    private Boolean faceDetected;

    @Column(length = 32)
    private String modelVersion;

    private Double threshold;

    @Column
    private String metaJson;


    @PrePersist
    public void prePersist() {
        if (this.id == null) this.id = UUID.randomUUID();
    }
}
