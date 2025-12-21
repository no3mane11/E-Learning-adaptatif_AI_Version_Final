package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.CreateEnrollmentRequest;
import com.elearning.adaptive.dto.EnrollmentDTO;

import java.util.List;

public interface EnrollmentService {

    EnrollmentDTO enrollStudent(Long studentId, CreateEnrollmentRequest req);

    EnrollmentDTO getEnrollment(Long id);

    void unenroll(Long enrollmentId, Long studentId);

    /**
     * Retourne les inscriptions de l'utilisateur connecté
     */
    List<EnrollmentDTO> getMyEnrollments(Long userId);
}
