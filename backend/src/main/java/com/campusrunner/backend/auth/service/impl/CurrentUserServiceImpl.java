package com.campusrunner.backend.auth.service.impl;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.campusrunner.backend.auth.jwt.JwtTokenProvider;
import com.campusrunner.backend.auth.service.CurrentUserService;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * Current user resolver service.
 */
@Service
public class CurrentUserServiceImpl implements CurrentUserService {

    private final JwtTokenProvider jwtTokenProvider;
    private final UserDao userDao;

    public CurrentUserServiceImpl(JwtTokenProvider jwtTokenProvider, UserDao userDao) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.userDao = userDao;
    }

    @Override
    @Transactional(readOnly = true)
    public User requireUser(String authorizationHeader, Long fallbackUserId) {
        Long userId = resolveUserId(authorizationHeader, fallbackUserId);
        User user = userDao.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "登录状态无效或已过期"));

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "账号已被禁用");
        }
        return user;
    }

    @Override
    @Transactional(readOnly = true)
    public Long resolveUserId(String authorizationHeader, Long fallbackUserId) {
        if (authorizationHeader != null && !authorizationHeader.isBlank()) {
            String token = extractBearerToken(authorizationHeader);
            return jwtTokenProvider.parseUserId(token);
        }

        // Keep compatibility with the existing X-User-Id based test flow.
        if (fallbackUserId != null) {
            return fallbackUserId;
        }

        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "缺少登录凭证");
    }

    private String extractBearerToken(String authorizationHeader) {
        if (!authorizationHeader.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authorization 必须使用 Bearer Token");
        }
        String token = authorizationHeader.substring("Bearer ".length()).trim();
        if (token.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token 不能为空");
        }
        return token;
    }
}
