package com.elearning.adaptive.repository;

import com.elearning.adaptive.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LessonRepository extends JpaRepository<Lesson, Long> {

    // ✅ CORRECT : accès via l'entité Course
    List<Lesson> findByCourse_IdOrderByOrdreAsc(Long courseId);

    List<Lesson> findByCourseId(Long courseId);
}
