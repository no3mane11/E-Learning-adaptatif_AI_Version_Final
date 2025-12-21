package com.elearning.adaptive.repository;

import com.elearning.adaptive.entity.FrustrationMetric;
import com.elearning.adaptive.entity.Session;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FrustrationMetricRepository extends JpaRepository<FrustrationMetric, UUID> {

    /**
     * Récupère toutes les métriques de frustration pour une session donnée.
     * @param session La session à rechercher.
     * @return Liste des métriques.
     */
    List<FrustrationMetric> findBySession(Session session);
}