package com.campusrunner.backend.admin.service;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.campusrunner.backend.auth.jwt.JwtTokenProvider;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.user.dao.UserDao;

public interface AdminPermissionService {
    User requireAdmin(String authorizationHeader);
}

