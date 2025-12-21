package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.*;
import java.util.UUID;

import com.elearning.adaptive.dto.SessionStats;
import java.util.UUID;

public interface EmotionEventService {
    EmotionEventDTO addEvent(UUID sessionId, Long actingUserId, EmotionEventRequest req);
    int addEventsBulk(UUID sessionId, Long actingUserId, BulkEmotionEventRequest bulkReq);

    // <-- Ajoute ceci :
    SessionStats getSessionStats(UUID sessionId, int windowSeconds);
}

