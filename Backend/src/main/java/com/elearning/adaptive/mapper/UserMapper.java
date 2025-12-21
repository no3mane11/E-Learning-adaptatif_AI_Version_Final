package com.elearning.adaptive.mapper;

import com.elearning.adaptive.dto.UserDTO;
import com.elearning.adaptive.entity.User;

public class UserMapper {

    public static UserDTO toDto(User u) {
        if (u == null) return null;
        return UserDTO.builder()
                .id(u.getId())
                .nom(u.getNom())
                .email(u.getEmail())
                .role(u.getRole() != null ? u.getRole().name() : null)
                .createdAt(u.getCreatedAt())
                .updatedAt(u.getUpdatedAt())
                .isActive(u.getIsActive())
                .build();
    }

    // used to update an entity from UpdateUserRequest (done in service for more control)
}
