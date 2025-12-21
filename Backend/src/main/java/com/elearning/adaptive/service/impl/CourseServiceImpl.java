package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.CreateCourseRequest;
import com.elearning.adaptive.dto.CourseDTO;
import com.elearning.adaptive.entity.Course;
import com.elearning.adaptive.entity.Role;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.mapper.CourseMapper;
import com.elearning.adaptive.repository.CourseRepository;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.CourseService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CourseServiceImpl implements CourseService {

    private final CourseRepository courseRepository;
    private final UserRepository userRepository;

    @Transactional
    @Override
    public CourseDTO createCourse(CreateCourseRequest req, Long actingUserId) {
        User teacher = userRepository.findById(actingUserId)
                .orElseThrow(() -> new IllegalArgumentException("Acting user not found"));

        if (teacher.getRole() != Role.TEACHER) {
            throw new AccessDeniedException("Only teachers can create courses");
        }

        Course course = Course.builder()
                .titre(req.getTitre())
                .description(req.getDescription())
                .teacher(teacher)
                .build();

        courseRepository.save(course);
        return CourseMapper.toDto(course);
    }

    // ✅ POINT CLÉ : fetch teacher ici
    @Override
    public Page<CourseDTO> listCourses(Pageable pageable) {
        return courseRepository.findAllWithTeacher(pageable)
                .map(CourseMapper::toDto);
    }

    @Override
    public CourseDTO getCourse(Long id) {
        Course c = courseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Course not found"));
        return CourseMapper.toDto(c);
    }

    @Transactional
    @Override
    public CourseDTO updateCourse(Long id, CreateCourseRequest req, Long actingUserId) {
        Course c = courseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Course not found"));

        User actor = userRepository.findById(actingUserId)
                .orElseThrow(() -> new IllegalArgumentException("Acting user not found"));

        if (!c.getTeacher().getId().equals(actor.getId())) {
            throw new AccessDeniedException("Not owner of the course");
        }

        c.setTitre(req.getTitre());
        c.setDescription(req.getDescription());

        return CourseMapper.toDto(courseRepository.save(c));
    }

    @Transactional
    @Override
    public void deleteCourse(Long id, Long actingUserId) {
        Course c = courseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Course not found"));

        if (!c.getTeacher().getId().equals(actingUserId)) {
            throw new AccessDeniedException("Not allowed");
        }

        courseRepository.delete(c);
    }
}
