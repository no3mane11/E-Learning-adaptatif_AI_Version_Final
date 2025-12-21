package com.elearning.adaptive.controller;

import com.elearning.adaptive.dto.CreateUserRequest;
import com.elearning.adaptive.dto.UpdateUserRequest;
import com.elearning.adaptive.dto.UserDTO;
import com.elearning.adaptive.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Validated
public class UserController {

    private final UserService userService;

    // Create / Register
    @PostMapping
    public ResponseEntity<UserDTO> create(@Valid @RequestBody CreateUserRequest req) {
        UserDTO dto = userService.createUser(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    // List (paginated)
    @GetMapping
    public ResponseEntity<Page<UserDTO>> list(Pageable pageable) {
        return ResponseEntity.ok(userService.listAll(pageable));
    }

    // Get by id
    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> get(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getById(id));
    }

    // Update
    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> update(@PathVariable Long id, @Valid @RequestBody UpdateUserRequest req) {
        return ResponseEntity.ok(userService.updateUser(id, req));
    }

    // Delete
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
