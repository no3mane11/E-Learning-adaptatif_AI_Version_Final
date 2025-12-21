package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.CreateCourseRequest;
import com.elearning.adaptive.dto.CourseDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import com.elearning.adaptive.dto.CreateCourseRequest;
import com.elearning.adaptive.dto.CourseDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;



public interface CourseService {
    CourseDTO createCourse(CreateCourseRequest req, Long actingUserId);

    // Signature correcte
    Page<CourseDTO> listCourses(Pageable pageable);

    CourseDTO getCourse(Long id);

    CourseDTO updateCourse(Long id, CreateCourseRequest req, Long actingUserId);

    void deleteCourse(Long id, Long actingUserId);
}