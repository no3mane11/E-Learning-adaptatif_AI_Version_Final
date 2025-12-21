package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.EmotionEventDTO;
import com.elearning.adaptive.dto.SessionStats;
import com.elearning.adaptive.entity.EmotionEvent;

public interface EmotionService {

    /**
     * Enregistre un nouvel événement émotionnel.
     * @param dto Données de l'événement émotionnel.
     * @return L'entité EmotionEvent persistée.
     */
    EmotionEvent recordEmotion(EmotionEventDTO dto);

    /**
     * Calcule les statistiques d'une session sur une fenêtre de temps donnée.
     * @param sessionId L'ID de la session.
     * @param windowSeconds La fenêtre de temps en secondes pour le calcul des stats.
     * @return Un objet SessionStats contenant les statistiques calculées.
     */
    SessionStats getSessionStats(String sessionId, int windowSeconds);
}
