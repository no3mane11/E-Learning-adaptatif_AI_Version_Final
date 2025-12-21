package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.LessonDTO;
import com.elearning.adaptive.entity.Lesson;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

public class LessonMapper {

    public static LessonDTO toDto(Lesson l) {
        if (l == null) return null;

        return LessonDTO.builder()
                .id(l.getId())
                .titre(l.getTitre())
                .typeContenu(l.getTypeContenu() != null ? l.getTypeContenu().name() : null)
                .ordre(l.getOrdre())
                .contenu(l.getContenu())
                .videoUrl(l.getVideoUrl())
                .courseId(l.getCourse() != null ? l.getCourse().getId() : null)
                .courseTitle(l.getCourse() != null ? l.getCourse().getTitre() : null)
                .createdAt(convertToOffset(l.getCreatedAt()))
                .updatedAt(convertToOffset(l.getUpdatedAt()))
                .build();
    }

    /**
     * Convertit LocalDateTime OU OffsetDateTime en OffsetDateTime (UTC).
     * Supporte les deux formats, donc évite toutes les erreurs d'incompatibilité.
     */
    private static OffsetDateTime convertToOffset(Object value) {
        if (value == null) return null;

        if (value instanceof OffsetDateTime) {
            return (OffsetDateTime) value;
        }

        if (value instanceof LocalDateTime) {
            return ((LocalDateTime) value).atOffset(ZoneOffset.UTC);
        }

        throw new IllegalArgumentException("Unsupported date type: " + value.getClass());
    }
}
