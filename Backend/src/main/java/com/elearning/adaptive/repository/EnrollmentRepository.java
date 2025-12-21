package com.elearning.adaptive.repository;

import com.elearning.adaptive.entity.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    Optional<Enrollment> findByUserIdAndCourseId(Long userId, Long courseId);

    boolean existsByUserIdAndCourseId(Long userId, Long courseId);
    List<Enrollment> findByUser_Id(Long userId); // Correction : Utilisez findByUser_Id
}
