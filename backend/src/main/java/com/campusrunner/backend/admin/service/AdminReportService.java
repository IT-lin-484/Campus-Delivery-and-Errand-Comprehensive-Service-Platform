package com.campusrunner.backend.admin.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dto.AdminHandleReportRequest;
import com.campusrunner.backend.admin.dto.AdminReportListResponse;
import com.campusrunner.backend.admin.dto.AdminReportSummaryResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.entity.AdminReport;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.admin.dao.AdminReportDao;

public interface AdminReportService {
    AdminReportListResponse listReports(AdminReportStatus status, String keyword, int page, int pageSize);
    AdminReportSummaryResponse handleReport(Long adminId, Long reportId, AdminHandleReportRequest request);
}

