package com.campusrunner.backend.admin.service.impl;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.campusrunner.backend.admin.service.AdminPermissionService;
import com.campusrunner.backend.auth.jwt.JwtTokenProvider;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * Admin permission validation service.
 */
@Service
public class AdminPermissionServiceImpl implements AdminPermissionService {

    private final JwtTokenProvider jwtTokenProvider;
    private final UserDao userDao;

    public AdminPermissionServiceImpl(JwtTokenProvider jwtTokenProvider, UserDao userDao) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.userDao = userDao;
    }

    @Override
    @Transactional(readOnly = true)
    public User requireAdmin(String authorizationHeader) {
        String token = extractBearerToken(authorizationHeader);
        Long userId = jwtTokenProvider.parseUserId(token);

        User user = userDao.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "登录状态无效或已过期"));
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "账号已被禁用");
        }
        if (user.getRole() != UserRole.ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "当前账号无管理员权限");
        }
        return user;
    }

    private String extractBearerToken(String authorizationHeader) {
        if (authorizationHeader == null || authorizationHeader.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "缺少 Authorization 请求头");
        }
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
