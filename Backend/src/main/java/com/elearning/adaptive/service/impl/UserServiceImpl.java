package com.elearning.adaptive.service.impl;

import com.elearning.adaptive.dto.CreateUserRequest;
import com.elearning.adaptive.dto.UpdateUserRequest;
import com.elearning.adaptive.dto.UserDTO;
import com.elearning.adaptive.entity.Role;
import com.elearning.adaptive.entity.User;
import com.elearning.adaptive.mapper.UserMapper;
import com.elearning.adaptive.repository.UserRepository;
import com.elearning.adaptive.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Transactional
    @Override
    public UserDTO createUser(CreateUserRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new IllegalArgumentException("Email already in use");
        }
        User u = User.builder()
                .nom(req.getNom())
                .email(req.getEmail())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .role(req.getRole() != null ? Role.valueOf(req.getRole()) : Role.STUDENT)
                .createdAt(OffsetDateTime.now())
                .isActive(true)
                .build();
        userRepository.save(u);
        return UserMapper.toDto(u);
    }

    @Override
    public UserDTO getById(Long id) {
        User u = userRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("User not found"));
        return UserMapper.toDto(u);
    }

    @Override
    public Page<UserDTO> listAll(Pageable pageable) {
        return userRepository.findAll(pageable).map(UserMapper::toDto);
    }

    @Transactional
    @Override
    public UserDTO updateUser(Long id, UpdateUserRequest req) {
        User u = userRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("User not found"));
        if (req.getNom() != null) u.setNom(req.getNom());
        if (req.getEmail() != null) {
            if (!u.getEmail().equals(req.getEmail()) && userRepository.existsByEmail(req.getEmail())) {
                throw new IllegalArgumentException("Email already in use");
            }
            u.setEmail(req.getEmail());
        }
        if (req.getPassword() != null) {
            u.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        }
        if (req.getRole() != null) u.setRole(Role.valueOf(req.getRole()));
        if (req.getIsActive() != null) u.setIsActive(req.getIsActive());
        userRepository.save(u);
        return UserMapper.toDto(u);
    }

    @Transactional
    @Override
    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) throw new IllegalArgumentException("User not found");
        userRepository.deleteById(id);
    }
}
