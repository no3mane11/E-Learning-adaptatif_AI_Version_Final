 package com.elearning.adaptive.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.GenericGenerator; // Reste nécessaire pour le générateur 'uuid2'
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "frustration_metrics")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FrustrationMetric {

    @Id
    @GeneratedValue(generator = "uuid2")
    @GenericGenerator(name = "uuid2", strategy = "uuid2")
    // 💡 CORRECTION : Suppression de columnDefinition = "BINARY(16)"
    @Column(name = "id")
    private UUID id;

    // La session à laquelle cette métrique est associée
    @ManyToOne(fetch = FetchType.LAZY)
    // 💡 VÉRIFICATION : Le nom de la colonne doit correspondre à la clé de la table Session
    @JoinColumn(name = "session_id", nullable = false)
    private Session session;

    // Le score de frustration (entre 0.0 et 1.0)
    @Column(name = "score", nullable = false)
    private Double score;

    // L'horodatage précis de la mesure (pris sur le frontend)
    @Column(name = "timestamp", nullable = false)
    private Instant timestamp;
}