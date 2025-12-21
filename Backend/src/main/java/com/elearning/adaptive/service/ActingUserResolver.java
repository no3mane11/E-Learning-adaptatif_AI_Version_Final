package com.elearning.adaptive.service;

import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.security.core.Authentication;

import java.util.Map;
import java.util.Optional;

/**
 * Service utilitaire centralisant la résolution de l'ID utilisateur ("acting user id")
 * à partir d'une Authentication fournie par Spring Security.
 *
 * Après modification du JwtAuthenticationFilter pour setter userId dans auth.getDetails(),
 * cette classe lira d'abord details puis tombera back sur auth.getName() (email) et
 * un lookup DB si nécessaire.
 */
@Service
@RequiredArgsConstructor
public class ActingUserResolver {

    private final UserRepository userRepository;

    /**
     * Tente de résoudre l'ID utilisateur à partir de Authentication.
     * - lit d'abord auth.getDetails() si c'est une Map contenant "userId"
     * - ensuite utilise auth.getName() (typiquement l'email dans ton filtre JWT)
     *   et effectue une recherche en base pour retrouver l'id.
     *
     * @param auth Authentication (peut être null)
     * @return userId (Long) ou null si non résolu
     */
    public Long resolve(Authentication auth) {
        if (auth == null) return null;

        // 1) check details (set in JwtAuthenticationFilter)
        Object details = auth.getDetails();
        if (details instanceof Map<?, ?>) {
            Object idObj = ((Map<?, ?>) details).get("userId");
            if (idObj instanceof Number) {
                return ((Number) idObj).longValue();
            }
            if (idObj instanceof String) {
                try {
                    return Long.parseLong((String) idObj);
                } catch (NumberFormatException ignored) {}
            }
        }

        // 2) fallback to auth.getName() (should be email per Jwt token generation)
        String name = auth.getName();
        if (name == null || name.isBlank()) return null;

        // try to find user by email
        Optional<User> maybe = userRepository.findByEmail(name.trim());
        return maybe.map(User::getId).orElse(null);
    }
}
