package com.campusrunner.backend.admin.service;

import java.util.List;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dto.AdminUpdateUserStatusRequest;
import com.campusrunner.backend.admin.dto.AdminUserListResponse;
import com.campusrunner.backend.admin.dto.AdminUserSummaryResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.user.dao.UserDao;

public interface AdminUserService {
    AdminUserListResponse listUsers(UserRole role, UserStatus status, String keyword, int page, int pageSize);
    AdminUserSummaryResponse updateUserStatus(Long adminId, Long userId, AdminUpdateUserStatusRequest request);
}

