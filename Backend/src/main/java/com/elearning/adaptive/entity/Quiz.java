package com.elearning.adaptive.entity;

import jakarta.persistence.*;
import java.util.List; // ⬅️ IMPORT AJOUTÉ POUR LIST
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

// Assurez-vous que les annotations Lombok sont bien importées
// (elles sont généralement dans le package lombok.*, non spécifié ici,
// mais supposées exister si vous utilisez @Getter, @Setter, etc.)
// Ex: import lombok.Getter;

@Entity
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Quiz {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String question;

    @ElementCollection
    @CollectionTable(name = "quiz_choices", joinColumns = @JoinColumn(name = "quiz_id"))
    @Column(name = "choice")
    private List<String> choices;

    private Integer correctAnswer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id")
    private Lesson lesson;
}