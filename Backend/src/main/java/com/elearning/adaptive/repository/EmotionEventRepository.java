package com.elearning.adaptive.repository;

import com.elearning.adaptive.entity.EmotionEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface EmotionEventRepository extends JpaRepository<EmotionEvent, UUID> {

    List<EmotionEvent> findBySessionIdOrderByTimestampDesc(UUID sessionId);

    List<EmotionEvent> findBySessionIdAndTimestampAfterOrderByTimestampAsc(UUID sessionId, OffsetDateTime after);


}
