package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.*;
import com.elearning.adaptive.entity.EmotionEvent;
import com.elearning.adaptive.entity.Session;
import com.elearning.adaptive.mapper.EmotionEventMapper;
import com.elearning.adaptive.repository.EmotionEventRepository;
import com.elearning.adaptive.repository.SessionRepository;
import com.elearning.adaptive.service.EmotionEventService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.DoubleSummaryStatistics;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EmotionEventServiceImpl implements EmotionEventService {

    private final EmotionEventRepository eventRepo;
    private final SessionRepository sessionRepo;

    @Transactional
    @Override
    public EmotionEventDTO addEvent(UUID sessionId, Long actingUserId, EmotionEventRequest req) {

        Session session = sessionRepo.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        if (!session.getEnrollment().getUser().getId().equals(actingUserId)) {
            throw new IllegalArgumentException("Unauthorized event submit");
        }

        EmotionEvent event = EmotionEvent.builder()
                .session(session)
                .timestamp(OffsetDateTime.parse(req.getTimestamp()))
                .frustrationScore(req.getFrustrationScore())
                .faceDetected(req.getFaceDetected())
                .modelVersion(req.getModelVersion())
                .threshold(req.getThreshold())
                .metaJson(req.getMeta() != null ? req.getMeta().toString() : null)
                .build();

        eventRepo.save(event);
        return EmotionEventMapper.toDto(event);
    }

    @Transactional
    @Override
    public int addEventsBulk(UUID sessionId, Long actingUserId, BulkEmotionEventRequest bulkReq) {

        Session session = sessionRepo.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        if (!session.getEnrollment().getUser().getId().equals(actingUserId)) {
            throw new IllegalArgumentException("Unauthorized event submit");
        }

        int count = 0;
        for (EmotionEventRequest r : bulkReq.getEvents()) {
            EmotionEvent event = EmotionEvent.builder()
                    .session(session)
                    .timestamp(OffsetDateTime.parse(r.getTimestamp()))
                    .frustrationScore(r.getFrustrationScore())
                    .faceDetected(r.getFaceDetected())
                    .modelVersion(r.getModelVersion())
                    .threshold(r.getThreshold())
                    .metaJson(r.getMeta() != null ? r.getMeta().toString() : null)
                    .build();

            eventRepo.save(event);
            count++;
        }

        return count;
    }

    // -----------------------
    // Statistiques de session
    // -----------------------
    @Override
    @Transactional(readOnly = true)
    public SessionStats getSessionStats(UUID sessionId, int windowSeconds) {
        Session session = sessionRepo.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        OffsetDateTime end = OffsetDateTime.now();
        OffsetDateTime start = end.minusSeconds(windowSeconds);

        // Récupère les events après start (méthode fournie dans le repository)
        List<EmotionEvent> events = eventRepo.findBySessionIdAndTimestampAfterOrderByTimestampAsc(sessionId, start);

        SessionStats stats = new SessionStats();
        stats.setSessionId(sessionId);
        stats.setWindowSeconds(windowSeconds);
        stats.setWindowStart(start);
        stats.setWindowEnd(end);

        if (events == null || events.isEmpty()) {
            stats.setCount(0);
            stats.setAvgScore(0.0);
            stats.setMaxScore(0.0);
            stats.setMinScore(0.0);
            stats.setFrustrationCount(0);
            return stats;
        }

        DoubleSummaryStatistics summary = events.stream()
                .mapToDouble(EmotionEvent::getFrustrationScore)
                .summaryStatistics();

        long frustrationCount = events.stream()
                .filter(e -> {
                    Double t = e.getThreshold();
                    double thr = (t != null) ? t : 0.3759;
                    return e.getFrustrationScore() > thr;
                })
                .count();

        stats.setCount((int) summary.getCount());
        stats.setAvgScore(summary.getAverage());
        stats.setMaxScore(summary.getMax());
        stats.setMinScore(summary.getMin());
        stats.setFrustrationCount(frustrationCount);

        return stats;
    }
}
