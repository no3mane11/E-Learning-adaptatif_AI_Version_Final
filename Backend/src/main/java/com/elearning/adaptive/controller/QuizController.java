package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.CreateQuizRequest;
import com.elearning.adaptive.dto.QuizDTO;
import com.elearning.adaptive.dto.SubmitQuizRequest; // ⬅️ IMPORT AJOUTÉ
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.QuizService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/quizzes")
@RequiredArgsConstructor
public class QuizController {

    private final QuizService quizService;
    private final UserRepository userRepository;

    // ---------------- CREATE QUIZ ----------------
    @PostMapping
    public ResponseEntity<QuizDTO> create(
            @RequestParam Long lessonId,
            @RequestBody CreateQuizRequest req,
            Authentication authentication
    ) {
        Long actingUserId = extractUserId(authentication);

        QuizDTO dto = quizService.create(lessonId, req, actingUserId);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    // ---------------- LIST BY LESSON ----------------
    @GetMapping("/lesson/{lessonId}")
    public ResponseEntity<List<QuizDTO>> listByLesson(
            @PathVariable Long lessonId
    ) {
        return ResponseEntity.ok(quizService.listByLesson(lessonId));
    }

    // ---------------- DELETE QUIZ ----------------
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            Authentication authentication
    ) {
        Long actingUserId = extractUserId(authentication);

        quizService.delete(id, actingUserId);
        return ResponseEntity.noContent().build();
    }


    // ---------------- SUBMIT ANSWERS ----------------
    @PostMapping("/submit-answers")
    public ResponseEntity<Void> submitAnswers(
            @RequestBody SubmitQuizRequest req,
            Authentication authentication
    ) {
        Long actingUserId = extractUserId(authentication);

        // La méthode submitAnswers gère toute la logique de validation et de scoring
        quizService.submitAnswers(req, actingUserId);

        return ResponseEntity.ok().build(); // 200 OK
    }

    // ------------------------------------------------
    // 🔑 UTIL : extraire userId depuis Authentication
    // ------------------------------------------------
    private Long extractUserId(Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "User not authenticated"
            );
        }

        Object principal = authentication.getPrincipal();

        // 🔹 CAS 1 : principal = email (String)
        if (principal instanceof String email) {
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.UNAUTHORIZED,
                            "User not found for email: " + email
                    ));
            return user.getId();
        }

        // 🔹 CAS 2 : principal = UserDetails
        if (principal instanceof org.springframework.security.core.userdetails.UserDetails ud) {
            String email = ud.getUsername();
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.UNAUTHORIZED,
                            "User not found for username: " + email
                    ));
            return user.getId();
        }

        throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Unsupported authentication principal"
        );
    }
}