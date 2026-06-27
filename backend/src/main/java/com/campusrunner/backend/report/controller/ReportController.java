package com.campusrunner.backend.report.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.auth.service.CurrentUserService;
import com.campusrunner.backend.report.dto.CreateReportRequest;
import com.campusrunner.backend.report.dto.ReportSummaryResponse;
import com.campusrunner.backend.report.service.ReportService;
import com.campusrunner.backend.user.entity.User;

import jakarta.validation.Valid;

/**
 * 鐢ㄦ埛涓炬姤鎺ュ彛銆? */
@Validated
@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {

    private final ReportService reportService;
    private final CurrentUserService currentUserService;

    public ReportController(ReportService reportService, CurrentUserService currentUserService) {
        this.reportService = reportService;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    public ReportSummaryResponse createReport(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @Valid @RequestBody CreateReportRequest request) {
        User reporter = currentUserService.requireUser(authorizationHeader, userId);
        return reportService.createReport(reporter.getId(), request);
    }
}

