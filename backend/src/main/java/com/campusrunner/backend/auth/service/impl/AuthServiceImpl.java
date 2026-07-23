package com.campusrunner.backend.auth.service.impl;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.campusrunner.backend.auth.dto.AdminRegisterRequest;
import com.campusrunner.backend.auth.dto.AuthResponse;
import com.campusrunner.backend.auth.dto.AuthUserResponse;
import com.campusrunner.backend.auth.dto.LoginRequest;
import com.campusrunner.backend.auth.dto.RegisterRequest;
import com.campusrunner.backend.auth.jwt.JwtTokenProvider;
import com.campusrunner.backend.auth.service.AuthService;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * Authentication service implementation.
 */
@Service
public class AuthServiceImpl implements AuthService {

    private static final String FIXED_ADMIN_INVITE_CODE = "9527";

    private final UserDao userDao;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthServiceImpl(
            UserDao userDao,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider jwtTokenProvider) {
        this.userDao = userDao;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        return registerByRole(
                request.getUsername(),
                request.getPassword(),
                request.getNickname(),
                request.getPhone(),
                UserRole.USER);
    }

    @Override
    @Transactional
    public AuthResponse registerAdmin(AdminRegisterRequest request) {
        validateAdminInviteCode(request.getInviteCode());
        return registerByRole(
                request.getUsername(),
                request.getPassword(),
                request.getNickname(),
                request.getPhone(),
                UserRole.ADMIN);
    }

    @Override
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = authenticateByPassword(request);
        return buildAuthResponse(user);
    }

    @Override
    @Transactional(readOnly = true)
    public AuthResponse loginAdmin(LoginRequest request) {
        User user = authenticateByPassword(request);
        if (user.getRole() != UserRole.ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "当前账号不是管理员");
        }
        return buildAuthResponse(user);
    }

    @Override
    @Transactional(readOnly = true)
    public AuthUserResponse getCurrentUser(String authorizationHeader) {
        String token = extractBearerToken(authorizationHeader);
        Long userId = jwtTokenProvider.parseUserId(token);

        User user = userDao.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "登录状态无效或已过期"));
        return toAuthUser(user);
    }

    private AuthResponse registerByRole(String username, String password, String nickname, String phone, UserRole role) {
        String normalizedUsername = normalizeUsername(username);
        if (userDao.existsByUsername(normalizedUsername)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "用户名已存在");
        }

        validatePhone(phone);

        User user = new User();
        user.setUsername(normalizedUsername);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setNickname(normalizeNickname(normalizedUsername, nickname));
        user.setPhone(normalizePhone(phone));
        user.setAvatarUrl(null);
        user.setCommonAddress(null);
        user.setBio(null);
        user.setAllowFriendRequest(true);
        user.setAllowSearch(true);
        user.setMessageDnd(false);
        user.setRole(role);
        user.setStatus(UserStatus.ACTIVE);

        User savedUser = userDao.save(user);
        return buildAuthResponse(savedUser);
    }

    private User authenticateByPassword(LoginRequest request) {
        String username = normalizeUsername(request.getUsername());
        User user = userDao.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "用户名或密码错误"));

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "账号已被禁用，请联系管理员");
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "用户名或密码错误");
        }
        return user;
    }

    private AuthResponse buildAuthResponse(User user) {
        AuthResponse response = new AuthResponse();
        response.setToken(jwtTokenProvider.createToken(user));
        response.setTokenType("Bearer");
        response.setExpiresIn(jwtTokenProvider.getExpiresInSeconds());
        response.setUser(toAuthUser(user));
        return response;
    }

    private AuthUserResponse toAuthUser(User user) {
        AuthUserResponse authUserResponse = new AuthUserResponse();
        authUserResponse.setId(user.getId());
        authUserResponse.setUsername(user.getUsername());
        authUserResponse.setNickname(user.getNickname());
        authUserResponse.setPhone(user.getPhone());
        authUserResponse.setAvatarUrl(user.getAvatarUrl());
        authUserResponse.setCommonAddress(user.getCommonAddress());
        authUserResponse.setBio(user.getBio());
        authUserResponse.setAllowFriendRequest(user.getAllowFriendRequest());
        authUserResponse.setAllowSearch(user.getAllowSearch());
        authUserResponse.setMessageDnd(user.getMessageDnd());
        authUserResponse.setRole(user.getRole());
        authUserResponse.setStatus(user.getStatus());
        return authUserResponse;
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
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token 不能为空！");
        }
        return token;
    }

    private String normalizeUsername(String username) {
        if (username == null) {
            return "";
        }
        return username.trim().toLowerCase();
    }

    private String normalizeNickname(String username, String nickname) {
        if (nickname == null || nickname.isBlank()) {
            return username;
        }
        return nickname.trim();
    }

    private String normalizePhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return null;
        }
        return phone.trim();
    }

    private void validatePhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return;
        }
        String normalizedPhone = phone.trim();
        if (!normalizedPhone.matches("^1[3-9]\\d{9}$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "手机号格式不正确");
        }
    }

    private void validateAdminInviteCode(String inviteCode) {
        if (inviteCode == null || inviteCode.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "管理员邀请码不能为空");
        }
        if (!FIXED_ADMIN_INVITE_CODE.equals(inviteCode.trim())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "管理员邀请码错误");
        }
    }
}
