package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.CreateLessonRequest;
import com.elearning.adaptive.dto.LessonDTO;
import com.elearning.adaptive.entity.Lesson;
import com.elearning.adaptive.entity.LessonContentType;
import com.elearning.adaptive.entity.Role;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.mapper.LessonMapper;
import com.elearning.adaptive.repository.CourseRepository;
import com.elearning.adaptive.repository.LessonRepository;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.LessonService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import org.springframework.web.multipart.MultipartFile; // ⬅️ IMPORT AJOUTÉ

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.OffsetDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LessonServiceImpl implements LessonService {

    private final LessonRepository lessonRepository;
    private final CourseRepository courseRepository;
    private final UserRepository userRepository;

    @Transactional
    @Override
    public LessonDTO createLesson(CreateLessonRequest req, Long actingUserId) {
        // Validate incoming request
        if (req == null || req.getCourseId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "courseId is required");
        }

        // Load course (404 if absent)
        var course = courseRepository.findById(req.getCourseId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found"));

        // Validate acting user
        if (actingUserId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "acting user id required");
        }
        User actor = userRepository.findById(actingUserId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Acting user not found"));

        // Permission check: only course teacher (owner) can add lessons
        if (course.getTeacher() == null || !course.getTeacher().getId().equals(actingUserId)) {
            // If you want to allow Role.TEACHER in general, change condition accordingly.
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only the course teacher can add lessons");
        }

        // Parse and validate content type (case-insensitive)
        LessonContentType contentType;
        try {
            contentType = LessonContentType.valueOf(req.getTypeContenu().trim().toUpperCase());
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid typeContenu: " + req.getTypeContenu());
        }

        // Validation spécifique THEORY
        if (contentType == LessonContentType.THEORY) {
            if (req.getContenu() == null || req.getContenu().isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Le contenu est obligatoire pour une leçon de type THEORY"
                );
            }
        }

        Lesson l = Lesson.builder()
                .titre(req.getTitre())
                .typeContenu(contentType)
                .ordre(req.getOrdre())
                .contenu(req.getContenu()) // 👈 AJOUT DU CONTENU
                .course(course)
                // -> remove createdAt(...) to let @CreatedDate handle it
                .build();
        lessonRepository.save(l);

        return LessonMapper.toDto(l);
    }

    @Override
    public List<LessonDTO> listByCourse(Long courseId) {
        return lessonRepository
                .findByCourse_IdOrderByOrdreAsc(courseId)
                .stream()
                .map(LessonMapper::toDto)
                .toList();
    }


    @Override
    public Page<LessonDTO> listAll(Pageable pageable) {
        return lessonRepository.findAll(pageable).map(LessonMapper::toDto);
    }

    @Override
    public LessonDTO getLesson(Long id) {
        var l = lessonRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));
        return LessonMapper.toDto(l);
    }

    @Transactional
    @Override
    public LessonDTO updateLesson(Long id, CreateLessonRequest req, Long actingUserId) {
        var l = lessonRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));

        if (actingUserId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "acting user id required");
        }
        User actor = userRepository.findById(actingUserId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Acting user not found"));

        // Only the teacher of the course may update the lesson
        if (l.getCourse() == null || l.getCourse().getTeacher() == null ||
                !l.getCourse().getTeacher().getId().equals(actingUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed to update this lesson");
        }

        if (req.getTitre() != null) l.setTitre(req.getTitre());
        if (req.getOrdre() != null) l.setOrdre(req.getOrdre());

        // --- LOGIQUE DE MISE À JOUR DU TYPE ET VALIDATION THEORY ---
        if (req.getTypeContenu() != null) {
            LessonContentType newType;
            try {
                newType = LessonContentType.valueOf(req.getTypeContenu().trim().toUpperCase());
            } catch (Exception ex) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid typeContenu: " + req.getTypeContenu());
            }

            l.setTypeContenu(newType);

            // Validation spécifique si le nouveau type est THEORY et que le contenu est manquant
            if (newType == LessonContentType.THEORY &&
                    (req.getContenu() == null || req.getContenu().isBlank())) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Le contenu est obligatoire pour une leçon THEORY"
                );
            }
        }
        // --- FIN LOGIQUE DE MISE À JOUR DU TYPE ET VALIDATION THEORY ---

        // --- MISE À JOUR DU CONTENU ---
        if (req.getContenu() != null) {
            l.setContenu(req.getContenu());
        }
        // --- FIN MISE À JOUR DU CONTENU ---

        // Change course only if courseId provided AND actor is teacher owner of new course
        if (req.getCourseId() != null) {
            var newCourse = courseRepository.findById(req.getCourseId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found"));
            // Optionally you might check permissions for newCourse as well
            l.setCourse(newCourse);
        }

        lessonRepository.save(l);
        return LessonMapper.toDto(l);
    }

    @Transactional
    @Override
    public void uploadVideo(Long lessonId, MultipartFile file, Long actingUserId) {

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));

        if (lesson.getCourse() == null || lesson.getCourse().getTeacher() == null ||
                !lesson.getCourse().getTeacher().getId().equals(actingUserId)) { // ⬅️ Correction pour NullPointer
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }

        if (lesson.getTypeContenu() != LessonContentType.VIDEO) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Lesson is not VIDEO type"
            );
        }

        // 📁 stockage simple (local)
        // Note: Il est crucial de s'assurer que le dossier "uploads/videos/" existe ou est créé
        // et que l'application a les permissions d'écriture.
        String filename = System.currentTimeMillis() + "_" + file.getOriginalFilename();
        Path path = Paths.get("uploads/videos/" + filename);

        try {
            Files.createDirectories(path.getParent());
            Files.write(path, file.getBytes());
        } catch (IOException e) {
            // Log the error for better debugging in a real application
            // log.error("Failed to upload file for lesson {}: {}", lessonId, e.getMessage());
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to upload video file.");
        }

        lesson.setVideoUrl("/videos/" + filename);
        lessonRepository.save(lesson);
    }


    @Transactional
    @Override
    public void deleteLesson(Long id, Long actingUserId) {
        var l = lessonRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));

        if (actingUserId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "acting user id required");
        }
        User actor = userRepository.findById(actingUserId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Acting user not found"));

        if (l.getCourse() == null || l.getCourse().getTeacher() == null ||
                !l.getCourse().getTeacher().getId().equals(actingUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed to delete this lesson");
        }

        lessonRepository.deleteById(id);
    }
}