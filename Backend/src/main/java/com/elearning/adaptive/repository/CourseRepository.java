package com.elearning.adaptive.repository;

import com.elearning.adaptive.entity.Course;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface CourseRepository extends JpaRepository<Course, Long> {

    // ✅ Fetch teacher correctement + pagination fonctionnelle
    @Query(
            value = """
            SELECT c FROM Course c
            JOIN FETCH c.teacher
        """,
            countQuery = """
            SELECT COUNT(c) FROM Course c
        """
    )
    Page<Course> findAllWithTeacher(Pageable pageable);

    List<Course> findByTeacherId(Long teacherId);
}
