package com.elearning.adaptive.security;

import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * JwtAuthenticationFilter : valide le token JWT et place l'Authentication dans SecurityContext.
 */
@Slf4j
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserRepository userRepo;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) throws ServletException {
        // Allow preflight
        if (HttpMethod.OPTIONS.matches(request.getMethod())) {
            return true;
        }

        String path = request.getServletPath(); // use servletPath to be robust with context path
        // Debug log (désactiver en prod si besoin)
        log.debug("JwtFilter.shouldNotFilter path={}, method={}", path, request.getMethod());

        // Allow docs and webjars
        if (path.startsWith("/v3/api-docs") || path.startsWith("/swagger") || path.startsWith("/webjars")) {
            return true;
        }

        // Allow login & register endpoints without JWT
        if ("/api/auth/login".equals(path) || "/api/auth/register".equals(path)) {
            return true;
        }

        // Everything else should be filtered
        return false;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");
        log.debug("JwtFilter.doFilterInternal servletPath={} authHeaderPresent={}", request.getServletPath(),
                authHeader != null && authHeader.startsWith("Bearer "));

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            try {
                String token = authHeader.substring(7).trim();
                if (token.isEmpty()) {
                    // no token content — treat as unauthenticated (let security handle)
                    filterChain.doFilter(request, response);
                    return;
                }

                Claims claims = jwtUtil.validateAndGetClaims(token);
                String email = claims.getSubject();

                // read role from token claims
                String roleFromToken = null;
                if (claims.get("role") != null) {
                    roleFromToken = claims.get("role").toString();
                } else if (claims.get("roles") != null) {
                    roleFromToken = claims.get("roles").toString();
                }

                Optional<User> userOpt = userRepo.findByEmail(email);

                String roleToUse = null;
                if (roleFromToken != null && !roleFromToken.isBlank()) {
                    roleToUse = roleFromToken;
                } else if (userOpt.isPresent() && userOpt.get().getRole() != null) {
                    roleToUse = userOpt.get().getRole().name();
                }

                if (roleToUse == null) {
                    log.warn("No role found for user email={}", email);
                    response.setStatus(HttpStatus.FORBIDDEN.value());
                    response.setContentType("application/json");
                    response.getWriter().write("{\"error\":\"No role found for user\"}");
                    return;
                }

                String normalized = roleToUse.startsWith("ROLE_") ? roleToUse : "ROLE_" + roleToUse;
                SimpleGrantedAuthority authority = new SimpleGrantedAuthority(normalized);

                var authToken = new UsernamePasswordAuthenticationToken(email, null, List.of(authority));
                userOpt.ifPresent(u -> authToken.setDetails(Map.of("userId", u.getId())));

                SecurityContextHolder.getContext().setAuthentication(authToken);
                log.debug("Authentication set for email={} role={}", email, normalized);

            } catch (JwtException ex) {
                log.warn("Invalid or expired JWT: {}", ex.getMessage());
                response.setStatus(HttpStatus.UNAUTHORIZED.value());
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"Invalid or expired JWT token\"}");
                return;
            } catch (Exception ex) {
                log.error("Authentication processing error", ex);
                response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR.value());
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"Authentication processing error\"}");
                return;
            }
        }

        // Continue filter chain (unauthenticated requests will be handled by Spring Security later)
        filterChain.doFilter(request, response);
    }
}
