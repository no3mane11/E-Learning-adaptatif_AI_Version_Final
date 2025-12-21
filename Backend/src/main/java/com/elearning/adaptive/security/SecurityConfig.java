package com.elearning.adaptive.security;

import com.elearning.adaptive.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    @Value("${app.jwt.enabled:true}")
    private boolean jwtEnabled;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {

        // CORS + CSRF
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.disable());

        if (!jwtEnabled) {
            // DEV MODE
            http.authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
        } else {
            // PROD / JWT MODE
            http.authorizeHttpRequests(auth -> auth

                    // AUTH
                    .requestMatchers("/api/auth/**").permitAll()

                    // SWAGGER
                    .requestMatchers(
                            "/swagger-ui/**",
                            "/swagger-ui.html",
                            "/v3/api-docs/**",
                            "/webjars/**",
                            "/actuator/**"
                    ).permitAll()
                            .requestMatchers("/api/debug/**").permitAll()

                    // COURSES
                    .requestMatchers(HttpMethod.GET, "/api/courses/**").authenticated()
                    .requestMatchers(HttpMethod.POST, "/api/courses").hasRole("TEACHER")
                    .requestMatchers(HttpMethod.PUT, "/api/courses/**").hasRole("TEACHER")
                    .requestMatchers(HttpMethod.DELETE, "/api/courses/**").hasRole("TEACHER")

                    // ENROLLMENTS (STUDENT ONLY)
                    .requestMatchers("/api/enrollments/**").hasRole("STUDENT")

                            // SESSIONS
// 1. D'abord la règle spécifique (Plus précise)
                            .requestMatchers("/api/sessions/teacher/**").hasRole("TEACHER")

// 2. Ensuite la règle globale (Moins précise)
                            .requestMatchers("/api/sessions/**").hasRole("STUDENT")
                    // RECOMMENDATIONS
                            .requestMatchers("/api/recommendations/**").hasAnyRole("STUDENT", "TEACHER")

                    // PREFLIGHT
                    .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                    // EVERYTHING ELSE
                    .anyRequest().authenticated()
            );

            // JWT FILTER
            JwtAuthenticationFilter jwtFilter =
                    new JwtAuthenticationFilter(jwtUtil, userRepository);

            http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        }

        // Stateless
        http.sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
        );

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // CORS (Flutter / Web / Mobile)
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOriginPatterns(List.of("*"));
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("*"));
        cfg.setExposedHeaders(List.of("Authorization"));
        cfg.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cfg);
        return source;
    }
}
