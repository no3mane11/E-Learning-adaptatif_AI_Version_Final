package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.CreateLessonRequest;
import com.elearning.adaptive.dto.LessonDTO;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.LessonService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.multipart.MultipartFile; // ⬅️ IMPORT AJOUTÉ

import jakarta.validation.Valid;
import java.lang.reflect.Method;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/lessons")
@RequiredArgsConstructor
public class LessonController {

    private static final Logger log = LoggerFactory.getLogger(LessonController.class);

    private final LessonService lessonService;
    private final UserRepository userRepository;

    @PostMapping
    public ResponseEntity<LessonDTO> create(
            @Valid @RequestBody CreateLessonRequest req,
            Authentication auth,
            @RequestHeader(value = "X-Acting-User-Id", required = false) Long actingHeaderId
    ) {
        Long userId = extractUserIdFromAuth(auth);
        if (userId == null && actingHeaderId != null) {
            userId = actingHeaderId;
            log.debug("CREATE lesson - fallback to header actingUserId={}", userId);
        } else {
            log.debug("CREATE lesson - actingUserId from auth={}", userId);
        }

        if (userId == null) {
            log.warn("CREATE lesson - no acting user id provided");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        }

        LessonDTO dto = lessonService.createLesson(req, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    @GetMapping("/course/{courseId}")
    public ResponseEntity<List<LessonDTO>> listByCourse(@PathVariable Long courseId) {
        return ResponseEntity.ok(lessonService.listByCourse(courseId));
    }

    @GetMapping
    public ResponseEntity<Page<LessonDTO>> listAll(Pageable pageable) {
        return ResponseEntity.ok(lessonService.listAll(pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<LessonDTO> get(@PathVariable Long id) {
        return ResponseEntity.ok(lessonService.getLesson(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<LessonDTO> update(
            @PathVariable Long id,
            @Valid @RequestBody CreateLessonRequest req,
            Authentication auth,
            @RequestHeader(value = "X-Acting-User-Id", required = false) Long actingHeaderId
    ) {
        Long userId = extractUserIdFromAuth(auth);
        if (userId == null && actingHeaderId != null) {
            userId = actingHeaderId;
            log.debug("UPDATE lesson id={} - fallback to header actingUserId={}", id, userId);
        } else {
            log.debug("UPDATE lesson id={} - actingUserId from auth={}", id, userId);
        }

        if (userId == null) {
            log.warn("UPDATE lesson - no acting user id provided");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        }

        return ResponseEntity.ok(lessonService.updateLesson(id, req, userId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            Authentication auth,
            @RequestHeader(value = "X-Acting-User-Id", required = false) Long actingHeaderId
    ) {
        Long userId = extractUserIdFromAuth(auth);
        if (userId == null && actingHeaderId != null) {
            userId = actingHeaderId;
            log.debug("DELETE lesson id={} - fallback to header actingUserId={}", id, userId);
        } else {
            log.debug("DELETE lesson id={} - actingUserId from auth={}", id, userId);
        }

        if (userId == null) {
            log.warn("DELETE lesson - no acting user id provided");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }

        lessonService.deleteLesson(id, userId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/video")
    public ResponseEntity<?> uploadVideo(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file,
            Authentication auth,
            @RequestHeader(value = "X-Acting-User-Id", required = false) Long actingHeaderId
    ) {
        Long userId = extractUserIdFromAuth(auth);
        if (userId == null && actingHeaderId != null) {
            userId = actingHeaderId;
        }

        if (userId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("User not authenticated");
        }

        lessonService.uploadVideo(id, file, userId);
        return ResponseEntity.ok().build();
    }


    // ---------------------------
    // Helper : extract acting user id
    // ---------------------------
    private Long extractUserIdFromAuth(Authentication auth) {
        if (auth == null) {
            log.debug("extractUserIdFromAuth: auth is null");
            return null;
        }
        Object principal = auth.getPrincipal();
        if (principal == null) {
            log.debug("extractUserIdFromAuth: principal is null");
            return null;
        }

        // 1) Try reflection: getId()
        try {
            Method getIdMethod = principal.getClass().getMethod("getId");
            if (getIdMethod != null) {
                Object idObj = getIdMethod.invoke(principal);
                if (idObj instanceof Number) {
                    long id = ((Number) idObj).longValue();
                    log.debug("extractUserIdFromAuth: resolved by getId() -> {}", id);
                    return id;
                }
                if (idObj instanceof String) {
                    try {
                        long id = Long.parseLong((String) idObj);
                        log.debug("extractUserIdFromAuth: resolved by getId() string -> {}", id);
                        return id;
                    } catch (NumberFormatException ignored) {}
                }
            }
        } catch (NoSuchMethodException ignored) {
            // no getId() — continue
        } catch (Exception e) {
            log.warn("extractUserIdFromAuth: reflection getId() failed: {}", e.toString());
        }

        // 2) If principal is a String (email from Jwt filter), lookup by email
        if (principal instanceof String) {
            String username = ((String) principal).trim();
            log.debug("extractUserIdFromAuth: principal is String -> {}", username);
            if (!username.isEmpty()) {
                try {
                    Optional<User> uOpt = userRepository.findByEmail(username);
                    if (uOpt.isPresent()) {
                        long id = uOpt.get().getId();
                        log.debug("extractUserIdFromAuth: resolved by email lookup -> {}", id);
                        return id;
                    } else {
                        log.debug("extractUserIdFromAuth: no user found for email {}", username);
                    }
                } catch (Exception e) {
                    log.warn("extractUserIdFromAuth: DB lookup failed for email {}: {}", username, e.toString());
                }
            }
        }

        // 3) If principal is UserDetails (Spring)
        if (principal instanceof org.springframework.security.core.userdetails.UserDetails) {
            String username = ((org.springframework.security.core.userdetails.UserDetails) principal).getUsername();
            log.debug("extractUserIdFromAuth: principal is UserDetails -> username={}", username);
            if (username != null && !username.isBlank()) {
                try {
                    long id = Long.parseLong(username);
                    log.debug("extractUserIdFromAuth: resolved by parsing username as id -> {}", id);
                    return id;
                } catch (NumberFormatException ignored) {}
                try {
                    Optional<User> uOpt = userRepository.findByEmail(username);
                    if (uOpt.isPresent()) {
                        long id = uOpt.get().getId();
                        log.debug("extractUserIdFromAuth: resolved by UserDetails email lookup -> {}", id);
                        return id;
                    } else {
                        log.debug("extractUserIdFromAuth: no user found for username {}", username);
                    }
                } catch (Exception e) {
                    log.warn("extractUserIdFromAuth: DB lookup failed for username {}: {}", username, e.toString());
                }
            }
        }

        log.debug("extractUserIdFromAuth: could not resolve user id from principal type {}", principal.getClass().getName());
        return null;
    }
}