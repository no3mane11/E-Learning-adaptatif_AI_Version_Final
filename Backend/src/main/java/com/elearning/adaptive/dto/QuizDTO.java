package com.elearning.adaptive.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuizDTO {
    public Long id;
    public Long lessonId;
    public String question;
    public List<String> choices;
    public Integer correctAnswer;
}