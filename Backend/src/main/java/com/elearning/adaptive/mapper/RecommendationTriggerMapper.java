package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.RecommendationTriggerDTO;
import com.elearning.adaptive.entity.RecommendationTrigger;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

public class RecommendationTriggerMapper {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static RecommendationTriggerDTO toDto(RecommendationTrigger t) {
        if (t == null) return null;

        JsonNode detailsNode = null;
        try {
            String raw = t.getDetailsJson();
            if (raw != null && !raw.isBlank()) {
                detailsNode = MAPPER.readTree(raw);
            }
        } catch (Exception e) {
            // ignore parsing errors - return null details in DTO
        }

        return RecommendationTriggerDTO.builder()
                .id(t.getId())
                .sessionId(t.getSessionId())
                .createdAt(t.getCreatedAt())
                .type(t.getType())
                .details(detailsNode)
                .build();
    }
}
