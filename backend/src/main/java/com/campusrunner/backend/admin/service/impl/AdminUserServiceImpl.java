package com.campusrunner.backend.admin.service.impl;

import java.util.List;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.admin.dto.AdminUpdateUserStatusRequest;
import com.campusrunner.backend.admin.dto.AdminUserListResponse;
import com.campusrunner.backend.admin.dto.AdminUserSummaryResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.service.AdminUserService;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * 管理员用户管理服务实现。
 */
@Service
public class AdminUserServiceImpl implements AdminUserService {

    private final UserDao userDao;
    private final AdminAuditLogDao adminAuditLogDao;

    public AdminUserServiceImpl(UserDao userDao, AdminAuditLogDao adminAuditLogDao) {
        this.userDao = userDao;
        this.adminAuditLogDao = adminAuditLogDao;
    }

    @Override
    @Transactional(readOnly = true)
    public AdminUserListResponse listUsers(
            UserRole role,
            UserStatus status,
            String keyword,
            int page,
            int pageSize) {
        Page<User> result = userDao.selectPage(
                new Page<>(page, pageSize),
                buildQueryWrapper(role, status, keyword));

        List<AdminUserSummaryResponse> list = result.getRecords().stream()
                .map(this::toSummary)
                .toList();

        AdminUserListResponse response = new AdminUserListResponse();
        response.setList(list);
        response.setTotal(result.getTotal());
        response.setPage(page);
        response.setPageSize(pageSize);
        return response;
    }

    @Override
    @Transactional
    public AdminUserSummaryResponse updateUserStatus(Long adminId, Long userId, AdminUpdateUserStatusRequest request) {
        User user = findUser(userId);
        if (request.getStatus() == UserStatus.BANNED) {
            if (user.getId().equals(adminId)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不能禁用自己的管理员账号");
            }
            if (user.getRole() == UserRole.ADMIN) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不能禁用其他管理员账号");
            }
        }

        String before = toSnapshot(user);
        user.setStatus(request.getStatus());
        User saved = userDao.save(user);

        writeAuditLog(
                adminId,
                "UPDATE_USER_STATUS",
                userId,
                before,
                toSnapshot(saved),
                normalizeText(request.getNote()));
        return toSummary(saved);
    }

    private LambdaQueryWrapper<User> buildQueryWrapper(UserRole role, UserStatus status, String keyword) {
        LambdaQueryWrapper<User> wrapper = Wrappers.lambdaQuery();
        if (role != null) {
            wrapper.eq(User::getRole, role);
        }
        if (status != null) {
            wrapper.eq(User::getStatus, status);
        }
        if (keyword != null && !keyword.isBlank()) {
            String normalizedKeyword = keyword.trim();
            wrapper.and(group -> {
                group.like(User::getUsername, normalizedKeyword)
                        .or()
                        .like(User::getNickname, normalizedKeyword)
                        .or()
                        .like(User::getPhone, normalizedKeyword);
                parseLongSafely(normalizedKeyword).ifPresent(id -> group.or().eq(User::getId, id));
            });
        }
        wrapper.orderByDesc(User::getCreatedAt);
        return wrapper;
    }

    private Optional<Long> parseLongSafely(String value) {
        try {
            return Optional.of(Long.parseLong(value));
        } catch (NumberFormatException exception) {
            return Optional.empty();
        }
    }

    private User findUser(Long userId) {
        return userDao.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在"));
    }

    private AdminUserSummaryResponse toSummary(User user) {
        AdminUserSummaryResponse response = new AdminUserSummaryResponse();
        response.setId(user.getId());
        response.setUsername(user.getUsername());
        response.setNickname(user.getNickname());
        response.setPhone(user.getPhone());
        response.setAvatarUrl(user.getAvatarUrl());
        response.setRole(user.getRole());
        response.setStatus(user.getStatus());
        response.setCreatedAt(user.getCreatedAt());
        response.setUpdatedAt(user.getUpdatedAt());
        return response;
    }

    private String toSnapshot(User user) {
        return "{"
                + "\"id\":" + user.getId() + ","
                + "\"role\":\"" + user.getRole().name() + "\","
                + "\"status\":\"" + user.getStatus().name() + "\""
                + "}";
    }

    private void writeAuditLog(
            Long operatorId,
            String action,
            Long targetId,
            String beforeData,
            String afterData,
            String note) {
        AdminAuditLog log = new AdminAuditLog();
        log.setOperatorId(operatorId);
        log.setAction(action);
        log.setTargetType("USER");
        log.setTargetId(targetId);
        log.setBeforeData(beforeData);
        log.setAfterData(afterData);
        log.setNote(note);
        adminAuditLogDao.save(log);
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
