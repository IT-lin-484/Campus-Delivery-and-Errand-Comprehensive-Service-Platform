package com.campusrunner.backend.admin.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.admin.dto.AdminOverviewResponse;
import com.campusrunner.backend.admin.service.AdminOverviewService;
import com.campusrunner.backend.admin.service.AdminPermissionService;

/**
 * 绠＄悊绔瑙堟帴鍙ｃ€? */
@RestController
@RequestMapping("/api/v1/admin/overview")
public class AdminOverviewController {

    private final AdminPermissionService adminPermissionService;
    private final AdminOverviewService adminOverviewService;

    public AdminOverviewController(AdminPermissionService adminPermissionService, AdminOverviewService adminOverviewService) {
        this.adminPermissionService = adminPermissionService;
        this.adminOverviewService = adminOverviewService;
    }

    @GetMapping
    public AdminOverviewResponse getOverview(@RequestHeader(value = "Authorization", required = false) String authorizationHeader) {
        adminPermissionService.requireAdmin(authorizationHeader);
        return adminOverviewService.getOverview();
    }
}

