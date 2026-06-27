package com.campusrunner.backend.admin.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.admin.dto.AdminHandleReportRequest;
import com.campusrunner.backend.admin.dto.AdminReportListResponse;
import com.campusrunner.backend.admin.dto.AdminReportSummaryResponse;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.admin.service.AdminPermissionService;
import com.campusrunner.backend.admin.service.AdminReportService;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 绠＄悊鍛樹妇鎶?宸ュ崟鎺ュ彛銆? */
@Validated
@RestController
@RequestMapping("/api/v1/admin/reports")
public class AdminReportController {

    private final AdminPermissionService adminPermissionService;
    private final AdminReportService adminReportService;

    public AdminReportController(AdminPermissionService adminPermissionService, AdminReportService adminReportService) {
        this.adminPermissionService = adminPermissionService;
        this.adminReportService = adminReportService;
    }

    @GetMapping
    public AdminReportListResponse listReports(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestParam(value = "status", required = false) AdminReportStatus status,
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "10") @Min(1) @Max(100) int pageSize) {
        adminPermissionService.requireAdmin(authorizationHeader);
        return adminReportService.listReports(status, keyword, page, pageSize);
    }

    @PostMapping("/{id}/handle")
    public AdminReportSummaryResponse handleReport(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable("id") Long reportId,
            @Valid @RequestBody AdminHandleReportRequest request) {
        Long adminId = adminPermissionService.requireAdmin(authorizationHeader).getId();
        return adminReportService.handleReport(adminId, reportId, request);
    }
}

