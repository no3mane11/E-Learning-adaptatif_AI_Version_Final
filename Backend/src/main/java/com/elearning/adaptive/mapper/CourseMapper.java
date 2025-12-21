package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.CourseDTO;
import com.elearning.adaptive.entity.Course;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

public class CourseMapper {

    public static CourseDTO toDto(Course c) {
        if (c == null) return null;

        Long teacherId = null;
        String teacherName = null;
        if (c.getTeacher() != null) {
            teacherId = c.getTeacher().getId();
            teacherName = c.getTeacher().getNom();
        }

        return CourseDTO.builder()
                .id(c.getId())
                .titre(c.getTitre())
                .description(c.getDescription())
                .teacherId(teacherId)
                .teacherName(teacherName)
                .createdAt(convertToOffset(c.getCreatedAt()))
                .updatedAt(convertToOffset(c.getUpdatedAt()))
                .build();
    }

    /**
     * Convertit LocalDateTime OU OffsetDateTime en OffsetDateTime (UTC).
     * Cette méthode évite toutes les erreurs de type incompatibles.
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
