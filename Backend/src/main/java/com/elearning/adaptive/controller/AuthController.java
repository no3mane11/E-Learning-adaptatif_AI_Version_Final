package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.AuthResponse;
import com.elearning.adaptive.dto.LoginRequest;
import com.elearning.adaptive.dto.RegisterRequest;
import com.elearning.adaptive.dto.UserDTO;
import com.elearning.adaptive.entity.Role;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.mapper.UserMapper;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.time.OffsetDateTime;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final UserRepository userRepo;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /**
     * Register endpoint
     */
    // Remplacer la méthode register actuelle par ce bloc
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest req) {
        try {
            if (req.getEmail() == null || req.getEmail().isBlank()) {
                return ResponseEntity.badRequest().body("Email is required");
            }
            if (req.getPassword() == null || req.getPassword().length() < 8) {
                return ResponseEntity.badRequest().body("Password must be at least 8 characters");
            }
            if (req.getNom() == null || req.getNom().isBlank()) {
                return ResponseEntity.badRequest().body("Full name (nom) is required");
            }

            if (userRepo.findByEmail(req.getEmail()).isPresent()) {
                return ResponseEntity.badRequest().body("Email already used");
            }

            // Resolve role (case-insensitive), default to STUDENT.
            Role role = Role.STUDENT;
            if (req.getRole() != null && !req.getRole().isBlank()) {
                try {
                    role = Role.valueOf(req.getRole().trim().toUpperCase());
                } catch (IllegalArgumentException ex) {
                    return ResponseEntity.badRequest().body("Invalid role: " + req.getRole());
                }
            }

            User u = User.builder()
                    .nom(req.getNom())
                    .email(req.getEmail())
                    .passwordHash(passwordEncoder.encode(req.getPassword()))
                    .role(role)
                    .isActive(true)
                    .createdAt(OffsetDateTime.now())
                    .build();

            // Save and use the persisted entity
            User saved = userRepo.save(u);

            // Generate token using the saved role (important)
            String token = jwtUtil.generateToken(saved.getEmail(), saved.getRole().name());
            UserDTO userDto = UserMapper.toDto(saved);

            return ResponseEntity.ok(new AuthResponse(token, userDto));
        } catch (Exception ex) {
            log.error("Error in register: {}", ex.getMessage(), ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Server error during registration");
        }
    }


    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req) {
        try {
            Optional<User> maybeUser = userRepo.findByEmail(req.getEmail());
            if (maybeUser.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid credentials");
            }

            User user = maybeUser.get();
            if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid credentials");
            }

            String token = jwtUtil.generateToken(user.getEmail(), user.getRole().name());
            UserDTO userDto = UserMapper.toDto(user);

            return ResponseEntity.ok(new AuthResponse(token, userDto));
        } catch (Exception ex) {
            log.error("Error in login: {}", ex.getMessage(), ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Server error during login");
        }
    }

    /**
     * GET /api/auth/me
     * Returns current authenticated user's DTO.
     */
    @GetMapping("/me")
    public ResponseEntity<?> me(org.springframework.security.core.Authentication auth) {
        try {
            if (auth == null || auth.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Not authenticated");
            }

            String email = auth.getName();

            Optional<User> maybeUser = userRepo.findByEmail(email);

            if (maybeUser.isPresent()) {
                User user = maybeUser.get();
                return ResponseEntity.ok(UserMapper.toDto(user));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found");
            }

        } catch (Exception ex) {
            log.error("Error in /me: {}", ex.getMessage(), ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Server error");
        }
    }

}
