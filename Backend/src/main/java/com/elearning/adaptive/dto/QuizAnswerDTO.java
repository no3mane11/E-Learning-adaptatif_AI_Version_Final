package com.elearning.adaptive.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class QuizAnswerDTO {
    private Long quizId;
    private Integer selectedChoiceIndex; // Index du choix sélectionné par l'étudiant
}