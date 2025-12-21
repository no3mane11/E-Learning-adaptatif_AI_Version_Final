package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.QuizDTO;
import com.elearning.adaptive.entity.Quiz;

public class QuizMapper {

    public static QuizDTO toDto(Quiz q) {
        if (q == null) return null;

        return QuizDTO.builder()
                .id(q.getId())
                .lessonId(q.getLesson() != null ? q.getLesson().getId() : null)
                .question(q.getQuestion())
                .choices(q.getChoices())
                .correctAnswer(q.getCorrectAnswer())
                .build();
    }
}
