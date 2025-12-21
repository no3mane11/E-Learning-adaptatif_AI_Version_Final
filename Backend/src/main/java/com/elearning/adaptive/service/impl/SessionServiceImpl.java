package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.FrustrationMetricDTO;
import com.elearning.adaptive.dto.SessionDTO;
import com.elearning.adaptive.entity.*;
import com.elearning.adaptive.mapper.SessionMapper;
import com.elearning.adaptive.repository.*;
import com.elearning.adaptive.service.SessionService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.OptionalDouble;

@Service
@RequiredArgsConstructor
@Slf4j
public class SessionServiceImpl implements SessionService {

    private final SessionRepository sessionRepo;
    private final EnrollmentRepository enrollmentRepo;
    private final FrustrationMetricRepository frustrationMetricRepository;
    // Les injections liées à l'IA et aux recommandations ont été supprimées ici

    private Session findSessionAndVerifyUser(UUID sessionId, Long actingUserId) {
        Session s = sessionRepo.findById(sessionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        if (!s.getEnrollment().getUser().getId().equals(actingUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not authorized to access this session");
        }
        return s;
    }

    @Transactional
    @Override
    public SessionDTO startSession(Long actingUserId, Long enrollmentId) {
        Enrollment enrollment = enrollmentRepo.findById(enrollmentId)
                .orElseThrow(() -> new IllegalArgumentException("Enrollment not found"));

        if (!enrollment.getUser().getId().equals(actingUserId)) {
            throw new IllegalArgumentException("Not authorized");
        }

        sessionRepo.findFirstByEnrollment_User_IdAndEndedAtIsNull(actingUserId)
                .ifPresent(s -> {
                    throw new IllegalStateException("User already has active session");
                });

        Session session = Session.builder()
                .enrollment(enrollment)
                .status(SessionStatus.IN_PROGRESS)
                .startedAt(OffsetDateTime.now())
                .durationSeconds(0L)
                .build();

        sessionRepo.save(session);
        return SessionMapper.toDto(session);
    }

    @Transactional
    @Override
    public SessionDTO updateTime(UUID sessionId, Long actingUserId, Long durationSeconds) {
        Session s = findSessionAndVerifyUser(sessionId, actingUserId);
        s.setDurationSeconds(durationSeconds);
        sessionRepo.save(s);
        return SessionMapper.toDto(s);
    }

    @Transactional
    @Override
    public SessionDTO endSession(UUID sessionId, Long actingUserId) {
        Session s = findSessionAndVerifyUser(sessionId, actingUserId);

        if (s.getStatus() == SessionStatus.COMPLETED) {
            log.warn("Attempt to end already completed session: {}", sessionId);
            return SessionMapper.toDto(s);
        }

        s.setStatus(SessionStatus.COMPLETED);
        s.setEndedAt(OffsetDateTime.now());
        sessionRepo.save(s);

        calculateAndSaveAverageFrustration(sessionId, actingUserId);

        return SessionMapper.toDto(s);
    }

    @Transactional
    @Override
    public void recordFrustrationMetric(UUID sessionId, Long actingUserId, FrustrationMetricDTO metricDTO) {
        // 1. Trouver la session et vérifier les droits
        Session s = findSessionAndVerifyUser(sessionId, actingUserId);

        // 2. Vérifier que la session est bien en cours
        if (s.getStatus() != SessionStatus.IN_PROGRESS) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Impossible d'enregistrer une métrique pour une session inactive");
        }

        // 3. Créer et sauvegarder la métrique
        FrustrationMetric metric = FrustrationMetric.builder()
                .session(s)
                .score(metricDTO.getScore())
                .timestamp(metricDTO.getTimestamp())
                .build();

        frustrationMetricRepository.save(metric);

        // 🎯 CRITIQUE : Recalculer la moyenne immédiatement pour le dashboard professeur
        calculateAndSaveAverageFrustration(sessionId, actingUserId);

        log.debug("Métrique enregistrée et moyenne mise à jour pour la session {}", sessionId);
    }
    @Transactional
    @Override
    public void calculateAndSaveAverageFrustration(UUID sessionId, Long actingUserId) {
        Session s = findSessionAndVerifyUser(sessionId, actingUserId);
        List<FrustrationMetric> metrics = frustrationMetricRepository.findBySession(s);

        OptionalDouble average = metrics.stream()
                .mapToDouble(FrustrationMetric::getScore)
                .average();

        if (average.isPresent()) {
            s.setAverageFrustrationScore(average.getAsDouble());
            sessionRepo.save(s);
            log.info("Average frustration saved for session {}: {}", sessionId, average.getAsDouble());
        } else {
            s.setAverageFrustrationScore(0.0);
            sessionRepo.save(s);
        }
    }

    @Override
    public List<SessionDTO> getMySessions(Long userId, boolean activeOnly) {
        List<Session> sessions = activeOnly
                ? sessionRepo.findByEnrollment_User_IdAndEndedAtIsNull(userId)
                : sessionRepo.findByEnrollment_User_Id(userId);

        return sessions.stream().map(SessionMapper::toDto).toList();
    }

    @Override
    public SessionDTO getActiveSession(Long userId) {
        return sessionRepo.findFirstByEnrollment_User_IdAndEndedAtIsNull(userId)
                .map(SessionMapper::toDto)
                .orElse(null);
    }

    @Override
    public List<SessionDTO> getSessionsForTeacher(Long teacherId) {
        List<Session> sessions = sessionRepo.findAllByTeacherId(teacherId);
        return sessions.stream().map(SessionMapper::toDto).toList();
    }
}