package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.SessionDTO;
import com.elearning.adaptive.entity.Session;

public class SessionMapper {

    // Dans SessionMapper.java
    public static SessionDTO toDto(Session s) {
        return SessionDTO.builder()
                .id(s.getId())
                .enrollmentId(s.getEnrollment().getId())
                .courseId(s.getEnrollment().getCourse().getId())
                .courseTitle(s.getEnrollment().getCourse().getTitre())
                // Correction ici : On utilise uniquement getNom()
                .studentName(s.getEnrollment().getUser().getNom())
                .averageFrustrationScore(s.getAverageFrustrationScore() != null ? s.getAverageFrustrationScore() : 0.0)
                .status(s.getStatus().name())
                .startedAt(s.getStartedAt())
                .endedAt(s.getEndedAt())
                .durationSeconds(s.getDurationSeconds())
                .build();
    }
}
