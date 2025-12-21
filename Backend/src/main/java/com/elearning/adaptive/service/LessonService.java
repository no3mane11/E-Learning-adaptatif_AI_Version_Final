package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.CreateLessonRequest;
import com.elearning.adaptive.dto.LessonDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface LessonService {
    LessonDTO createLesson(CreateLessonRequest req, Long actingUserId);
    List<LessonDTO> listByCourse(Long courseId);
    Page<LessonDTO> listAll(Pageable pageable);
    LessonDTO getLesson(Long id);
    LessonDTO updateLesson(Long id, CreateLessonRequest req, Long actingUserId);
    void deleteLesson(Long id, Long actingUserId);
    void uploadVideo(Long lessonId, MultipartFile file, Long actingUserId);

}
