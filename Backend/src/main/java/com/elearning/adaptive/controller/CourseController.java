package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.CreateCourseRequest;
import com.elearning.adaptive.dto.CourseDTO;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository; // ⬅️ AJOUTÉ
import com.elearning.adaptive.service.CourseService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication; // ⬅️ AJOUTÉ
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException; // ⬅️ AJOUTÉ

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;
    private final UserRepository userRepository; // ⬅️ AJOUTÉ POUR L'EXTRACTION DE L'ID

    // -------------------------------------------------------------
    // CREATE
    // -------------------------------------------------------------
    @PostMapping
    public ResponseEntity<CourseDTO> createCourse(
            @RequestBody CreateCourseRequest req,
            Authentication auth // ⬅️ Utilisation de l'objet Authentication
    ) {
        // Extraction de l'ID utilisateur à partir du contexte de sécurité
        Long actingUserId = extractUserId(auth);

        // Cette vérification n'est plus nécessaire si SecurityConfig a 'authenticated()'
        // mais elle assure une double sécurité si le rôle n'a pas été trouvé.
        if (actingUserId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated or ID not found.");
        }

        CourseDTO dto = courseService.createCourse(req, actingUserId);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    // -------------------------------------------------------------
    // LIST (pas de changement nécessaire)
    // -------------------------------------------------------------
    @GetMapping
    public ResponseEntity<Page<CourseDTO>> list(Pageable pageable) {
        return ResponseEntity.ok(courseService.listCourses(pageable));
    }

    // -------------------------------------------------------------
    // GET ONE (pas de changement nécessaire)
    // -------------------------------------------------------------
    @GetMapping("/{id}")
    public ResponseEntity<CourseDTO> get(@PathVariable Long id) {
        return ResponseEntity.ok(courseService.getCourse(id));
    }

    // -------------------------------------------------------------
    // UPDATE
    // -------------------------------------------------------------
    @PutMapping("/{id}")
    public ResponseEntity<CourseDTO> update(
            @PathVariable Long id,
            @RequestBody CreateCourseRequest req,
            Authentication auth // ⬅️ Utilisation de l'objet Authentication
    ) {
        Long actingUserId = extractUserId(auth);

        if (actingUserId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated or ID not found.");
        }

        CourseDTO dto = courseService.updateCourse(id, req, actingUserId);
        return ResponseEntity.ok(dto);
    }

    // -------------------------------------------------------------
    // DELETE
    // -------------------------------------------------------------
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            Authentication auth // ⬅️ Utilisation de l'objet Authentication
    ) {
        Long actingUserId = extractUserId(auth);

        if (actingUserId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated or ID not found.");
        }

        courseService.deleteCourse(id, actingUserId);
        return ResponseEntity.noContent().build();
    }

    // ------------------------------------------------
    // 🔑 UTIL : méthode d'extraction de l'ID (à réutiliser depuis QuizController par exemple)
    // ------------------------------------------------
    private Long extractUserId(Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "User not authenticated"
            );
        }

        Object principal = authentication.getPrincipal();

        // Le principal est l'email (String) après validation du JWT
        if (principal instanceof String email) {
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.UNAUTHORIZED,
                            "User not found for email: " + email
                    ));
            return user.getId();
        }

        // Si l'application utilise un UserDetails
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