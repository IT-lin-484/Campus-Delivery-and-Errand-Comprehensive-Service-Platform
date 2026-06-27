package com.campusrunner.backend.auth.service;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;
import com.campusrunner.backend.auth.dto.AdminRegisterRequest;
import com.campusrunner.backend.auth.dto.AuthResponse;
import com.campusrunner.backend.auth.dto.AuthUserResponse;
import com.campusrunner.backend.auth.dto.LoginRequest;
import com.campusrunner.backend.auth.dto.RegisterRequest;
import com.campusrunner.backend.auth.jwt.JwtTokenProvider;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.user.dao.UserDao;

public interface AuthService {
    AuthResponse register(RegisterRequest request);
    AuthResponse registerAdmin(AdminRegisterRequest request);
    AuthResponse login(LoginRequest request);
    AuthResponse loginAdmin(LoginRequest request);
    AuthUserResponse getCurrentUser(String authorizationHeader);
}

