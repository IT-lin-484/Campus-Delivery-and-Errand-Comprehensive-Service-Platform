package com.campusrunner.backend.admin.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.admin.dto.AdminUpdateUserStatusRequest;
import com.campusrunner.backend.admin.dto.AdminUserListResponse;
import com.campusrunner.backend.admin.dto.AdminUserSummaryResponse;
import com.campusrunner.backend.admin.service.AdminPermissionService;
import com.campusrunner.backend.admin.service.AdminUserService;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 绠＄悊鍛樼敤鎴风鐞嗘帴鍙ｃ€? */
@Validated
@RestController
@RequestMapping("/api/v1/admin/users")
public class AdminUserController {

    private final AdminPermissionService adminPermissionService;
    private final AdminUserService adminUserService;

    public AdminUserController(AdminPermissionService adminPermissionService, AdminUserService adminUserService) {
        this.adminPermissionService = adminPermissionService;
        this.adminUserService = adminUserService;
    }

    @GetMapping
    public AdminUserListResponse listUsers(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestParam(value = "role", required = false) UserRole role,
            @RequestParam(value = "status", required = false) UserStatus status,
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "10") @Min(1) @Max(100) int pageSize) {
        adminPermissionService.requireAdmin(authorizationHeader);
        return adminUserService.listUsers(role, status, keyword, page, pageSize);
    }

    @PatchMapping("/{id}/status")
    public AdminUserSummaryResponse updateStatus(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable("id") Long userId,
            @Valid @RequestBody AdminUpdateUserStatusRequest request) {
        Long adminId = adminPermissionService.requireAdmin(authorizationHeader).getId();
        return adminUserService.updateUserStatus(adminId, userId, request);
    }
}

