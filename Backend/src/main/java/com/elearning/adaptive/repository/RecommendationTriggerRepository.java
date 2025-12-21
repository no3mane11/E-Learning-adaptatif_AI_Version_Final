package com.elearning.adaptive.repository;

import com.elearning.adaptive.entity.RecommendationTrigger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecommendationTriggerRepository extends JpaRepository<RecommendationTrigger, Long> {
    List<RecommendationTrigger> findBySessionIdOrderByCreatedAtDesc(String sessionId);
}
