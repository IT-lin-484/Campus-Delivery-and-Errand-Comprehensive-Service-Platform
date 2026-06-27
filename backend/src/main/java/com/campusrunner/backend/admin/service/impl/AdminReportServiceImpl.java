package com.campusrunner.backend.admin.service.impl;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.admin.dao.AdminReportDao;
import com.campusrunner.backend.admin.dto.AdminHandleReportRequest;
import com.campusrunner.backend.admin.dto.AdminReportListResponse;
import com.campusrunner.backend.admin.dto.AdminReportSummaryResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.entity.AdminReport;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.admin.service.AdminReportService;

/**
 * 管理员举报管理服务实现。
 */
@Service
public class AdminReportServiceImpl implements AdminReportService {

    private final AdminReportDao adminReportDao;
    private final AdminAuditLogDao adminAuditLogDao;

    public AdminReportServiceImpl(
            AdminReportDao adminReportDao,
            AdminAuditLogDao adminAuditLogDao) {
        this.adminReportDao = adminReportDao;
        this.adminAuditLogDao = adminAuditLogDao;
    }

    @Override
    @Transactional(readOnly = true)
    public AdminReportListResponse listReports(AdminReportStatus status, String keyword, int page, int pageSize) {
        Page<AdminReport> result = adminReportDao.selectPage(
                new Page<>(page, pageSize),
                buildQueryWrapper(status, keyword));

        List<AdminReportSummaryResponse> list = result.getRecords().stream()
                .map(this::toSummary)
                .toList();

        AdminReportListResponse response = new AdminReportListResponse();
        response.setList(list);
        response.setTotal(result.getTotal());
        response.setPage(page);
        response.setPageSize(pageSize);
        return response;
    }

    @Override
    @Transactional
    public AdminReportSummaryResponse handleReport(Long adminId, Long reportId, AdminHandleReportRequest request) {
        AdminReport report = findReport(reportId);
        String before = toSnapshot(report);

        if (request.getStatus() == AdminReportStatus.OPEN) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "处理后的状态不能为待处理");
        }

        report.setStatus(request.getStatus());
        report.setHandleNote(normalizeText(request.getHandleNote()));
        report.setHandledBy(adminId);
        report.setHandledAt(LocalDateTime.now());

        AdminReport saved = adminReportDao.save(report);
        writeAuditLog(adminId, reportId, before, toSnapshot(saved), "管理员处理举报");
        return toSummary(saved);
    }

    private LambdaQueryWrapper<AdminReport> buildQueryWrapper(AdminReportStatus status, String keyword) {
        LambdaQueryWrapper<AdminReport> wrapper = Wrappers.lambdaQuery();
        if (status != null) {
            wrapper.eq(AdminReport::getStatus, status);
        }
        if (keyword != null && !keyword.isBlank()) {
            String normalizedKeyword = keyword.trim();
            wrapper.and(group -> {
                group.like(AdminReport::getCategory, normalizedKeyword)
                        .or()
                        .like(AdminReport::getDescription, normalizedKeyword)
                        .or()
                        .like(AdminReport::getTargetType, normalizedKeyword);
                parseLongSafely(normalizedKeyword).ifPresent(id -> group
                        .or()
                        .eq(AdminReport::getId, id)
                        .or()
                        .eq(AdminReport::getTargetId, id));
            });
        }
        wrapper.orderByDesc(AdminReport::getCreatedAt);
        return wrapper;
    }

    private Optional<Long> parseLongSafely(String value) {
        try {
            return Optional.of(Long.parseLong(value));
        } catch (NumberFormatException exception) {
            return Optional.empty();
        }
    }

    private AdminReport findReport(Long reportId) {
        return adminReportDao.findById(reportId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "举报记录不存在"));
    }

    private AdminReportSummaryResponse toSummary(AdminReport report) {
        AdminReportSummaryResponse response = new AdminReportSummaryResponse();
        response.setId(report.getId());
        response.setCategory(report.getCategory());
        response.setTargetType(report.getTargetType());
        response.setTargetId(report.getTargetId());
        response.setReporterId(report.getReporterId());
        response.setDescription(report.getDescription());
        response.setStatus(report.getStatus());
        response.setHandledBy(report.getHandledBy());
        response.setHandleNote(report.getHandleNote());
        response.setHandledAt(report.getHandledAt());
        response.setCreatedAt(report.getCreatedAt());
        return response;
    }

    private String toSnapshot(AdminReport report) {
        return "{"
                + "\"id\":" + report.getId() + ","
                + "\"status\":\"" + report.getStatus().name() + "\","
                + "\"handledBy\":" + (report.getHandledBy() == null ? "null" : report.getHandledBy())
                + "}";
    }

    private void writeAuditLog(
            Long operatorId,
            Long targetId,
            String beforeData,
            String afterData,
            String note) {
        AdminAuditLog log = new AdminAuditLog();
        log.setOperatorId(operatorId);
        log.setAction("HANDLE_REPORT");
        log.setTargetType("REPORT");
        log.setTargetId(targetId);
        log.setBeforeData(beforeData);
        log.setAfterData(afterData);
        log.setNote(note);
        adminAuditLogDao.save(log);
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
