package com.campusrunner.backend.auth.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.auth.dto.AdminRegisterRequest;
import com.campusrunner.backend.auth.dto.AuthResponse;
import com.campusrunner.backend.auth.dto.AuthUserResponse;
import com.campusrunner.backend.auth.dto.LoginRequest;
import com.campusrunner.backend.auth.dto.RegisterRequest;
import com.campusrunner.backend.auth.service.AuthService;

import jakarta.validation.Valid;

/**
 * 鐧诲綍娉ㄥ唽鎺ュ彛銆? */
@Validated
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/admin/register")
    public AuthResponse adminRegister(@Valid @RequestBody AdminRegisterRequest request) {
        return authService.registerAdmin(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/admin/login")
    public AuthResponse adminLogin(@Valid @RequestBody LoginRequest request) {
        return authService.loginAdmin(request);
    }

    @GetMapping("/me")
    public AuthUserResponse me(@RequestHeader(value = "Authorization", required = false) String authorizationHeader) {
        return authService.getCurrentUser(authorizationHeader);
    }
}

