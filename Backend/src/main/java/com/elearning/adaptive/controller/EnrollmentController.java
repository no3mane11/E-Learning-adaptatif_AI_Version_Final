package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.CreateEnrollmentRequest;
import com.elearning.adaptive.dto.EnrollmentDTO;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.EnrollmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/enrollments")
@RequiredArgsConstructor
public class EnrollmentController {

    private final EnrollmentService enrollmentService;
    private final UserRepository userRepository;

    // ----------------------------------------------------
    // CREATE ENROLLMENT (STUDENT)
    // ----------------------------------------------------
    @PostMapping
    public ResponseEntity<EnrollmentDTO> enroll(
            @Valid @RequestBody CreateEnrollmentRequest req
    ) {
        User student = getAuthenticatedUser();

        EnrollmentDTO dto =
                enrollmentService.enrollStudent(student.getId(), req);

        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    // ----------------------------------------------------
    // GET MY ENROLLMENTS
    // ----------------------------------------------------
    @GetMapping("/my")
    public List<EnrollmentDTO> getMyEnrollments() {
        User student = getAuthenticatedUser();
        return enrollmentService.getMyEnrollments(student.getId());
    }

    // ----------------------------------------------------
    // GET ENROLLMENT BY ID
    // ----------------------------------------------------
    @GetMapping("/{id}")
    public ResponseEntity<EnrollmentDTO> get(@PathVariable Long id) {
        EnrollmentDTO dto = enrollmentService.getEnrollment(id);
        return ResponseEntity.ok(dto);
    }

    // ----------------------------------------------------
    // UNENROLL (STUDENT)
    // ----------------------------------------------------
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> unenroll(@PathVariable Long id) {
        User student = getAuthenticatedUser();
        enrollmentService.unenroll(id, student.getId());
        return ResponseEntity.noContent().build();
    }

    // ----------------------------------------------------
    // HELPER
    // ----------------------------------------------------
    private User getAuthenticatedUser() {
        Authentication auth =
                SecurityContextHolder.getContext().getAuthentication();

        if (auth == null || !auth.isAuthenticated()) {
            throw new RuntimeException("Unauthenticated");
        }

        String email = auth.getName();

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
