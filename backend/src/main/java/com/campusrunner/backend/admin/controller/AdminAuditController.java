package com.campusrunner.backend.admin.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.admin.dto.AdminAuditLogListResponse;
import com.campusrunner.backend.admin.service.AdminAuditService;
import com.campusrunner.backend.admin.service.AdminPermissionService;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 绠＄悊鍛樺璁℃棩蹇楁帴鍙ｃ€? */
@Validated
@RestController
@RequestMapping("/api/v1/admin/audit")
public class AdminAuditController {

    private final AdminPermissionService adminPermissionService;
    private final AdminAuditService adminAuditService;

    public AdminAuditController(AdminPermissionService adminPermissionService, AdminAuditService adminAuditService) {
        this.adminPermissionService = adminPermissionService;
        this.adminAuditService = adminAuditService;
    }

    @GetMapping
    public AdminAuditLogListResponse listLogs(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestParam(value = "action", required = false) String action,
            @RequestParam(value = "target_type", required = false) String targetType,
            @RequestParam(value = "operator_id", required = false) Long operatorId,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "20") @Min(1) @Max(100) int pageSize) {
        adminPermissionService.requireAdmin(authorizationHeader);
        return adminAuditService.listLogs(action, targetType, operatorId, page, pageSize);
    }
}

