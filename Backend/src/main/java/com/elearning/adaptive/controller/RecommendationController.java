package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.RecommendationDTO;
import com.elearning.adaptive.entity.Recommendation;
import com.elearning.adaptive.mapper.RecommendationMapper;
import com.elearning.adaptive.repository.RecommendationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationRepository recommendationRepository;
    private final RecommendationMapper recommendationMapper;

    /**
     * Récupère les recommandations non lues pour une session spécifique.
     * Flutter appellera ceci périodiquement ou via un timer.
     */
    @GetMapping("/session/{sessionId}/unread")
    public ResponseEntity<List<RecommendationDTO>> getUnreadRecommendations(@PathVariable UUID sessionId) {
        List<Recommendation> unread = recommendationRepository
                .findBySessionIdAndReadFalseOrderByCreatedAtDesc(sessionId);

        List<RecommendationDTO> dtos = unread.stream()
                .map(recommendationMapper::toDto)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    /**
     * Marque une recommandation comme lue pour qu'elle ne s'affiche plus sur Flutter.
     */
    @PatchMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable Long id) {
        recommendationRepository.findById(id).ifPresent(reco -> {
            reco.setRead(true);
            recommendationRepository.save(reco);
        });
        return ResponseEntity.ok().build();
    }
}