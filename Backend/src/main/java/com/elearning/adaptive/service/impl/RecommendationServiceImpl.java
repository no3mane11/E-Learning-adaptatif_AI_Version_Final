package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.RecommendationTriggerDTO;
import com.elearning.adaptive.entity.RecommendationTrigger;
import com.elearning.adaptive.mapper.RecommendationTriggerMapper;
import com.elearning.adaptive.repository.RecommendationTriggerRepository;
import com.elearning.adaptive.service.RecommendationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecommendationServiceImpl implements RecommendationService {

    private final RecommendationTriggerRepository repo;

    @Override
    public RecommendationTriggerDTO createTrigger(RecommendationTriggerDTO dto) {
        RecommendationTrigger t = RecommendationTrigger.builder()
                .sessionId(dto.getSessionId())
                .createdAt(dto.getCreatedAt() != null ? dto.getCreatedAt() : OffsetDateTime.now())
                .type(dto.getType())
                .detailsJson(dto.getDetails() != null ? dto.getDetails().toString() : null)
                .build();

        RecommendationTrigger saved = repo.save(t);
        return RecommendationTriggerMapper.toDto(saved);
    }

    @Override
    public List<RecommendationTriggerDTO> listTriggersForSession(String sessionId) {
        return repo.findBySessionIdOrderByCreatedAtDesc(sessionId)
                .stream()
                .map(RecommendationTriggerMapper::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public RecommendationTriggerDTO getTrigger(Long id) {
        return repo.findById(id).map(RecommendationTriggerMapper::toDto).orElse(null);
    }

    @Override
    public void deleteTrigger(Long id) {
        repo.deleteById(id);
    }
}
