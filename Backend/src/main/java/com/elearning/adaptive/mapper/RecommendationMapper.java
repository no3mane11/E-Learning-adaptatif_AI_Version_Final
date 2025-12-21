package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.RecommendationDTO;
import com.elearning.adaptive.entity.Recommendation;
import org.springframework.stereotype.Component;

@Component
public class RecommendationMapper {

    public RecommendationDTO toDto(Recommendation entity) {
        if (entity == null) return null;
        return RecommendationDTO.builder()
                .id(entity.getId())
                .content(entity.getContent())
                .triggerType(entity.getTriggerType())
                .createdAt(entity.getCreatedAt())
                .read(entity.isRead())
                .build();
    }
}