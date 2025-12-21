package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.EnrollmentDTO;
import com.elearning.adaptive.entity.Enrollment;

public class EnrollmentMapper {

    public static EnrollmentDTO toDto(Enrollment e) {
        if (e == null) return null;

        return EnrollmentDTO.builder()
                .id(e.getId())
                .userId(e.getUser() != null ? e.getUser().getId() : null)
                .userName(e.getUser() != null ? e.getUser().getNom() : null)
                .courseId(e.getCourse() != null ? e.getCourse().getId() : null)
                .courseTitle(e.getCourse() != null ? e.getCourse().getTitre() : null)
                .enrolledAt(e.getEnrolledAt())
                .build();
    }
}
