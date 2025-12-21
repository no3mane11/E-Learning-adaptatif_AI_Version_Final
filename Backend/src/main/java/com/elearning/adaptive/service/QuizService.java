package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.CreateQuizRequest;
import com.elearning.adaptive.dto.QuizDTO;
import com.elearning.adaptive.dto.SubmitQuizRequest; // ⬅️ IMPORT AJOUTÉ

import java.util.List;

public interface QuizService {

    QuizDTO create(Long lessonId, CreateQuizRequest req, Long actingUserId);

    List<QuizDTO> listByLesson(Long lessonId);

    void delete(Long quizId, Long actingUserId);

    // La méthode qui posait problème
    void submitAnswers(SubmitQuizRequest req, Long actingUserId);
}