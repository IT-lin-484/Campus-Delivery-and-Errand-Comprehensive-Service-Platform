package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.admin.enums.AdminReportStatus;

/**
 * 涓炬姤/宸ュ崟鍒楄〃椤广€?
 */
@Data
public class AdminReportSummaryResponse {
    private Long id;
    private String category;
    private String targetType;
    private Long targetId;
    private Long reporterId;
    private String description;
    private AdminReportStatus status;
    private Long handledBy;
    private String handleNote;
    private LocalDateTime handledAt;
    private LocalDateTime createdAt;

}
