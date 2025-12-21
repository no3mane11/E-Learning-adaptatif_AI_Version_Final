package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.FrustrationMetricDTO;
import com.elearning.adaptive.dto.SessionDTO;
import com.elearning.adaptive.dto.StartSessionRequest;
import com.elearning.adaptive.dto.UpdateSessionTimeRequest;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.SessionService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/sessions")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;
    private final UserRepository userRepository;

    /**
     * Récupère l'utilisateur connecté via le contexte de sécurité
     */
    private User currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    /**
     * ✅ ENDPOINT RÉACTIVÉ : Enregistre les scores de frustration envoyés par le Frontend.
     * La logique d'IA ayant été supprimée du service, cet appel est maintenant 100% sûr.
     */
    @PostMapping("/frustration-metric")
    public ResponseEntity<Void> recordFrustrationMetric(
            @Valid @RequestBody FrustrationMetricDTO metricDTO
    ) {
        Long actingUserId = currentUser().getId();
        UUID sessionId = metricDTO.getSessionId();

        // Appel au service (qui se contente maintenant de sauvegarder en DB)
        sessionService.recordFrustrationMetric(sessionId, actingUserId, metricDTO);

        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @PostMapping("/start")
    public ResponseEntity<SessionDTO> start(@RequestBody StartSessionRequest req) {
        return ResponseEntity.ok(
                sessionService.startSession(
                        currentUser().getId(),
                        req.getEnrollmentId()
                )
        );
    }

    @PutMapping("/{id}/time")
    public ResponseEntity<SessionDTO> updateTime(
            @PathVariable UUID id,
            @RequestBody UpdateSessionTimeRequest req
    ) {
        return ResponseEntity.ok(
                sessionService.updateTime(
                        id,
                        currentUser().getId(),
                        req.getDurationSeconds()
                )
        );
    }

    @PutMapping("/{id}/end")
    public ResponseEntity<SessionDTO> end(@PathVariable UUID id) {
        return ResponseEntity.ok(
                sessionService.endSession(id, currentUser().getId())
        );
    }

    @GetMapping("/my")
    public ResponseEntity<List<SessionDTO>> mySessions(
            @RequestParam(defaultValue = "false") boolean activeOnly
    ) {
        return ResponseEntity.ok(
                sessionService.getMySessions(
                        currentUser().getId(),
                        activeOnly
                )
        );
    }

    @GetMapping("/active")
    public ResponseEntity<SessionDTO> active() {
        SessionDTO dto = sessionService.getActiveSession(currentUser().getId());
        return dto == null
                ? ResponseEntity.noContent().build()
                : ResponseEntity.ok(dto);
    }

    @GetMapping("/teacher/monitor")
    @PreAuthorize("hasRole('TEACHER')")
    public ResponseEntity<List<SessionDTO>> getTeacherMonitor(Authentication auth) {
        // Extraction sécurisée de l'ID utilisateur à partir de l'objet Authentication
        var details = (Map<String, Object>) ((UsernamePasswordAuthenticationToken) auth).getDetails();
        Long teacherId = Long.valueOf(details.get("userId").toString());

        return ResponseEntity.ok(sessionService.getSessionsForTeacher(teacherId));
    }
}