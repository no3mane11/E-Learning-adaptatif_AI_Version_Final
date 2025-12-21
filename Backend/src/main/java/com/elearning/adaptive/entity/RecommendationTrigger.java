package com.elearning.adaptive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "recommendation_triggers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecommendationTrigger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "session_id", nullable = false)
    private String sessionId;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "type", nullable = false)
    private String type;  // exemple: "FRUSTRATION_HIGH"

    @Column(name = "details_json", columnDefinition = "text")
    private String detailsJson;  // JSON contenant les détails du trigger
}
