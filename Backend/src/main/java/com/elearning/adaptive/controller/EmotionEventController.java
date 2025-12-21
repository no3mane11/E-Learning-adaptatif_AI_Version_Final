package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.*;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.EmotionEventService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.lang.reflect.Method;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/sessions/{sessionId}/emotion")
@RequiredArgsConstructor
public class EmotionEventController {

    private static final Logger log = LoggerFactory.getLogger(EmotionEventController.class);

    private final EmotionEventService eventService;
    private final UserRepository userRepo;

    @PostMapping
    public ResponseEntity<?> addEvent(
            @PathVariable UUID sessionId,
            @Valid @RequestBody EmotionEventRequest req,
            Authentication auth,
            @RequestHeader(value = "X-Acting-User-Id", required = false) Long actingHeaderId
    ) {
        Long userId = extractUserId(auth);
        if (userId == null && actingHeaderId != null) {
            userId = actingHeaderId;
            log.debug("addEvent: fallback to header X-Acting-User-Id={}", userId);
        } else {
            log.debug("addEvent: userId from auth={}", userId);
        }

        if (userId == null) {
            log.warn("addEvent: no acting user id provided");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Acting user id not provided (Authentication missing and no X-Acting-User-Id header)");
        }

        EmotionEventDTO dto = eventService.addEvent(sessionId, userId, req);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    @PostMapping("/bulk")
    public ResponseEntity<?> addBulk(
            @PathVariable UUID sessionId,
            @Valid @RequestBody BulkEmotionEventRequest req,
            Authentication auth,
            @RequestHeader(value = "X-Acting-User-Id", required = false) Long actingHeaderId
    ) {
        Long userId = extractUserId(auth);
        if (userId == null && actingHeaderId != null) {
            userId = actingHeaderId;
            log.debug("addBulk: fallback to header X-Acting-User-Id={}", userId);
        } else {
            log.debug("addBulk: userId from auth={}", userId);
        }

        if (userId == null) {
            log.warn("addBulk: no acting user id provided");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Acting user id not provided (Authentication missing and no X-Acting-User-Id header)");
        }

        int stored = eventService.addEventsBulk(sessionId, userId, req);
        return ResponseEntity.status(HttpStatus.CREATED).body("Stored " + stored + " events");
    }

    // Helper method (same as others)
    private Long extractUserId(Authentication auth) {
        if (auth == null) return null;

        Object principal = auth.getPrincipal();
        if (principal == null) return null;

        try {
            Method m = principal.getClass().getMethod("getId");
            Object val = m.invoke(principal);
            if (val instanceof Number) return ((Number) val).longValue();
            if (val instanceof String) return Long.parseLong((String) val);
        } catch (NoSuchMethodException ignored) {
        } catch (Exception e) {
            log.debug("extractUserId reflection error: {}", e.toString());
        }

        if (principal instanceof UserDetails) {
            String username = ((UserDetails) principal).getUsername();
            try { return Long.parseLong(username); } catch (Exception ignored) {}
            Optional<User> u = userRepo.findByEmail(username);
            return u.map(User::getId).orElse(null);
        }

        return null;
    }
}
