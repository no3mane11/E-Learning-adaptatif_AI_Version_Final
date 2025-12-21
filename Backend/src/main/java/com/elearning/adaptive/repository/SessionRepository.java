package com.elearning.adaptive.repository;

import com.elearning.adaptive.entity.Session;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SessionRepository extends JpaRepository<Session, UUID> {

    List<Session> findByEnrollment_User_Id(Long userId);

    List<Session> findByEnrollment_User_IdAndEndedAtIsNull(Long userId);

    Optional<Session> findFirstByEnrollment_User_IdAndEndedAtIsNull(Long userId);

    // Dans SessionRepository.java
    @Query("SELECT s FROM Session s WHERE s.enrollment.course.teacher.id = :teacherId")
    List<Session> findAllByTeacherId(@Param("teacherId") Long teacherId);
}
