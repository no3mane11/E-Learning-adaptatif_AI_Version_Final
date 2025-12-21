package com.elearning.adaptive.service;

import com.elearning.adaptive.dto.CreateUserRequest;
import com.elearning.adaptive.dto.UpdateUserRequest;
import com.elearning.adaptive.dto.UserDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface UserService {
    UserDTO createUser(CreateUserRequest req);
    UserDTO getById(Long id);
    Page<UserDTO> listAll(Pageable pageable);
    UserDTO updateUser(Long id, UpdateUserRequest req);
    void deleteUser(Long id);
}
