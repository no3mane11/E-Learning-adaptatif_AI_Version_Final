package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.CreateEnrollmentRequest;
import com.elearning.adaptive.dto.EnrollmentDTO;
import com.elearning.adaptive.entity.Course;
import com.elearning.adaptive.entity.Enrollment;
import com.elearning.adaptive.entity.Role;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.mapper.EnrollmentMapper;
import com.elearning.adaptive.repository.CourseRepository;
import com.elearning.adaptive.repository.EnrollmentRepository;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.EnrollmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EnrollmentServiceImpl implements EnrollmentService {

    private final EnrollmentRepository enrollmentRepo;
    private final UserRepository userRepo;
    private final CourseRepository courseRepo;

    // ---------------------------------------------------
    // ENROLL
    // ---------------------------------------------------
    @Transactional
    @Override
    public EnrollmentDTO enrollStudent(Long studentId, CreateEnrollmentRequest req) {

        User student = userRepo.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (student.getRole() != Role.STUDENT) {
            throw new IllegalArgumentException("Only students can enroll in courses");
        }

        Course course = courseRepo.findById(req.getCourseId())
                .orElseThrow(() -> new IllegalArgumentException("Course not found"));

        if (enrollmentRepo.existsByUserIdAndCourseId(studentId, req.getCourseId())) {
            throw new IllegalArgumentException("Already enrolled in this course");
        }

        Enrollment enrollment = Enrollment.builder()
                .user(student)
                .course(course)
                .enrolledAt(OffsetDateTime.now())
                .build();

        enrollmentRepo.save(enrollment);
        return EnrollmentMapper.toDto(enrollment);
    }

    // ---------------------------------------------------
    // GET ONE
    // ---------------------------------------------------
    @Override
    public EnrollmentDTO getEnrollment(Long id) {
        Enrollment e = enrollmentRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Enrollment not found"));
        return EnrollmentMapper.toDto(e);
    }

    // ---------------------------------------------------
    // UNENROLL
    // ---------------------------------------------------
    @Transactional
    @Override
    public void unenroll(Long enrollmentId, Long studentId) {

        Enrollment e = enrollmentRepo.findById(enrollmentId)
                .orElseThrow(() -> new IllegalArgumentException("Enrollment not found"));

        if (!e.getUser().getId().equals(studentId)) {
            throw new IllegalArgumentException("You can only unenroll yourself");
        }

        enrollmentRepo.delete(e);
    }

    // ---------------------------------------------------
    // GET MY ENROLLMENTS (JWT-READY)
    // ---------------------------------------------------
    @Override
    public List<EnrollmentDTO> getMyEnrollments(Long userId) {
        return enrollmentRepo.findByUser_Id(userId)
                .stream()
                .map(EnrollmentMapper::toDto)
                .collect(Collectors.toList());
    }
}
