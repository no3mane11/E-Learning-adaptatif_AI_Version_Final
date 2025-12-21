package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.RecommendationTriggerDTO;
import com.elearning.adaptive.dto.RecommendationTriggerDTO;
import com.elearning.adaptive.dto.RecommendationTriggerDTO;
import com.elearning.adaptive.entity.RecommendationTrigger;

import java.util.List;

public interface RecommendationService {
    RecommendationTriggerDTO createTrigger(RecommendationTriggerDTO dto);
    List<RecommendationTriggerDTO> listTriggersForSession(String sessionId);
    RecommendationTriggerDTO getTrigger(Long id);
    void deleteTrigger(Long id);
}
