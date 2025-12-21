package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.CreateQuizRequest;
import com.elearning.adaptive.dto.QuizDTO;
import com.elearning.adaptive.dto.SubmitQuizRequest; // ⬅️ IMPORT AJOUTÉ
import com.elearning.adaptive.dto.QuizAnswerDTO;   // ⬅️ IMPORT AJOUTÉ
import com.elearning.adaptive.entity.Lesson;
import com.elearning.adaptive.entity.LessonContentType;
import com.elearning.adaptive.entity.Quiz;
import com.elearning.adaptive.mapper.QuizMapper;
import com.elearning.adaptive.repository.LessonRepository;
import com.elearning.adaptive.repository.QuizRepository;
import com.elearning.adaptive.service.QuizService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class QuizServiceImpl implements QuizService {

    private final QuizRepository quizRepository;
    private final LessonRepository lessonRepository;

    @Override
    public QuizDTO create(Long lessonId, CreateQuizRequest req, Long actingUserId) {

        log.debug("Creating quiz | lessonId={} | userId={}", lessonId, actingUserId);

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));

        if (lesson.getTypeContenu() != LessonContentType.QUIZ) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Lesson is not of type QUIZ");
        }

        Long ownerId = lesson.getCourse().getTeacher().getId();
        if (!ownerId.equals(actingUserId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Only the course owner can add quizzes");
        }

        if (req.getChoices() == null || req.getChoices().size() < 2 ||
                req.getCorrectAnswer() == null ||
                req.getCorrectAnswer() < 0 ||
                req.getCorrectAnswer() >= req.getChoices().size()) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Invalid quiz choices or correct answer");
        }

        Quiz quiz = Quiz.builder()
                .question(req.getQuestion())
                .choices(req.getChoices())
                .correctAnswer(req.getCorrectAnswer())
                .lesson(lesson)
                .build();

        quizRepository.save(quiz);

        log.info("Quiz created successfully | quizId={}", quiz.getId());
        return QuizMapper.toDto(quiz);
    }

    @Override
    public List<QuizDTO> listByLesson(Long lessonId) {
        return quizRepository.findByLessonId(lessonId)
                .stream()
                .map(QuizMapper::toDto)
                .toList();
    }

    @Override
    public void delete(Long quizId, Long actingUserId) {

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Quiz not found"));

        Long ownerId = quiz.getLesson().getCourse().getTeacher().getId();
        if (!ownerId.equals(actingUserId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Only the course owner can delete this quiz");
        }

        quizRepository.deleteById(quizId);
        log.info("Quiz deleted | quizId={}", quizId);
    }


    @Override
    @Transactional
    public void submitAnswers(SubmitQuizRequest req, Long actingUserId) {
        // 1. Validation basique
        if (req.getSessionId() == null || req.getLessonId() == null || req.getAnswers() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Requête de soumission invalide.");
        }

        // 2. Récupérer l'utilisateur (actingUserId) et la session (SessionRepository.findById(req.getSessionId()))
        // User user = userRepository.findById(actingUserId).orElseThrow(...);
        // Session session = sessionRepository.findById(req.getSessionId()).orElseThrow(...);

        // 3. Traiter les réponses et calculer le score
        int totalQuestions = 0;
        int correctAnswers = 0;

        for (QuizAnswerDTO answer : req.getAnswers()) {
            totalQuestions++;

            Quiz quiz = quizRepository.findById(answer.getQuizId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Quiz non trouvé: " + answer.getQuizId()));

            // Comparer la réponse de l'étudiant avec la réponse correcte
            if (quiz.getCorrectAnswer().equals(answer.getSelectedChoiceIndex())) {
                correctAnswers++;
            }

            // 💡 Logique pour enregistrer chaque réponse individuelle (facultatif) ou le résultat agrégé
        }

        double score = totalQuestions > 0 ? (double) correctAnswers / totalQuestions * 100 : 0;

        // 4. Enregistrer le résultat (Nécessite une entité QuizResult, un repository et une injection)
        // Exemple :
        // QuizResult result = QuizResult.builder()
        //     .lessonId(req.getLessonId())
        //     .sessionId(req.getSessionId())
        //     .score(score)
        //     .totalQuestions(totalQuestions)
        //     .correctAnswers(correctAnswers)
        //     .build();
        // quizResultRepository.save(result);

        log.info("Quiz submitted successfully for session {} with score: {}%", req.getSessionId(), score);
    }
}