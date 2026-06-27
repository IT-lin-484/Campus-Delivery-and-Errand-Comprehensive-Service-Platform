package com.campusrunner.backend.report.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.report.enums.ReportTargetType;

/**
 * 涓炬姤鎻愪氦鍝嶅簲銆?
 */
@Data
public class ReportSummaryResponse {

    private Long id;
    private String category;
    private ReportTargetType targetType;
    private Long targetId;
    private AdminReportStatus status;
    private LocalDateTime createdAt;

}
