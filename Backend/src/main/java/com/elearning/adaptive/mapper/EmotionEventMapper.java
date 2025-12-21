package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.EmotionEventDTO;
import com.elearning.adaptive.entity.EmotionEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class EmotionEventMapper {

    // Utiliser un ObjectMapper partagé (ou injecté si tu préfères)
    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static EmotionEventDTO toDto(EmotionEvent e) {
        if (e == null) return null;

        JsonNode metaNode = null;
        try {
            String raw = e.getMetaJson();
            if (raw != null && !raw.isBlank()) {
                metaNode = MAPPER.readTree(raw);
            }
        } catch (Exception ex) {
            // fallback: log l'erreur et laisser metaNode null
            log.warn("Failed to parse metaJson for EmotionEvent id={} : {}", e.getId(), ex.getMessage());
        }

        return EmotionEventDTO.builder()
                .id(e.getId())
                .sessionId(e.getSession().getId())
                .timestamp(e.getTimestamp())
                .frustrationScore(e.getFrustrationScore())
                .faceDetected(e.getFaceDetected())
                .modelVersion(e.getModelVersion())
                .threshold(e.getThreshold())
                .meta(metaNode)
                .build();
    }
}
