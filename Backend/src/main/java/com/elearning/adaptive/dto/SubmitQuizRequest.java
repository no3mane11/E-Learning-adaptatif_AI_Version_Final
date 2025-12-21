package com.elearning.adaptive.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class SubmitQuizRequest {
    private String sessionId; // UUID de la session
    private Long lessonId;
    private List<QuizAnswerDTO> answers;
}