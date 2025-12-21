package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.FrustrationMetricDTO;
import com.elearning.adaptive.dto.SessionDTO;

import java.util.List;
import java.util.UUID;

public interface SessionService {

    SessionDTO startSession(Long actingUserId, Long enrollmentId);

    SessionDTO updateTime(UUID sessionId, Long actingUserId, Long durationSeconds);

    SessionDTO endSession(UUID sessionId, Long actingUserId);

    void recordFrustrationMetric(UUID sessionId, Long actingUserId, FrustrationMetricDTO metricDTO);

    void calculateAndSaveAverageFrustration(UUID sessionId, Long actingUserId);



    List<SessionDTO> getMySessions(Long userId, boolean activeOnly);

    SessionDTO getActiveSession(Long userId);

    List<SessionDTO> getSessionsForTeacher(Long teacherId);
}