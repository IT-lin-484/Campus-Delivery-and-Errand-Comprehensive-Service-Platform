package com.campusrunner.backend.admin.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.admin.dto.AdminConfigResponse;
import com.campusrunner.backend.admin.dto.AdminUpdateConfigRequest;
import com.campusrunner.backend.admin.service.AdminConfigService;
import com.campusrunner.backend.admin.service.AdminPermissionService;

import jakarta.validation.Valid;

/**
 * 绠＄悊鍛樼郴缁熼厤缃帴鍙ｃ€? */
@Validated
@RestController
@RequestMapping("/api/v1/admin/config")
public class AdminConfigController {

    private final AdminPermissionService adminPermissionService;
    private final AdminConfigService adminConfigService;

    public AdminConfigController(AdminPermissionService adminPermissionService, AdminConfigService adminConfigService) {
        this.adminPermissionService = adminPermissionService;
        this.adminConfigService = adminConfigService;
    }

    @GetMapping
    public AdminConfigResponse getConfig(@RequestHeader(value = "Authorization", required = false) String authorizationHeader) {
        adminPermissionService.requireAdmin(authorizationHeader);
        return adminConfigService.getConfig();
    }

    @PutMapping
    public AdminConfigResponse updateConfig(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @Valid @RequestBody AdminUpdateConfigRequest request) {
        Long adminId = adminPermissionService.requireAdmin(authorizationHeader).getId();
        return adminConfigService.updateConfig(adminId, request);
    }
}

