package com.campusrunner.backend.auth.service;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.campusrunner.backend.auth.jwt.JwtTokenProvider;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.user.dao.UserDao;

public interface CurrentUserService {
    User requireUser(String authorizationHeader, Long fallbackUserId);
    Long resolveUserId(String authorizationHeader, Long fallbackUserId);
}

