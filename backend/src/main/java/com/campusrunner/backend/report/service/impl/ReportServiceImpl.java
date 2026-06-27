package com.campusrunner.backend.report.service.impl;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.campusrunner.backend.admin.dao.AdminReportDao;
import com.campusrunner.backend.admin.entity.AdminReport;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.order.entity.Order;
import com.campusrunner.backend.report.dto.CreateReportRequest;
import com.campusrunner.backend.report.dto.ReportSummaryResponse;
import com.campusrunner.backend.report.enums.ReportTargetType;
import com.campusrunner.backend.report.service.ReportService;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;

/**
 * User report service implementation.
 */
@Service
public class ReportServiceImpl implements ReportService {

    private final AdminReportDao adminReportDao;
    private final OrderDao orderDao;
    private final UserDao userDao;

    public ReportServiceImpl(
            AdminReportDao adminReportDao,
            OrderDao orderDao,
            UserDao userDao) {
        this.adminReportDao = adminReportDao;
        this.orderDao = orderDao;
        this.userDao = userDao;
    }

    @Override
    @Transactional
    public ReportSummaryResponse createReport(Long reporterId, CreateReportRequest request) {
        validateTarget(reporterId, request.getTargetType(), request.getTargetId());

        AdminReport report = new AdminReport();
        report.setCategory(normalizeText(request.getCategory()));
        report.setTargetType(request.getTargetType().name());
        report.setTargetId(request.getTargetId());
        report.setReporterId(reporterId);
        report.setDescription(normalizeText(request.getDescription()));
        report.setStatus(AdminReportStatus.OPEN);

        AdminReport saved = adminReportDao.save(report);
        return toResponse(saved);
    }

    private void validateTarget(Long reporterId, ReportTargetType targetType, Long targetId) {
        if (targetType == ReportTargetType.ORDER) {
            Order order = orderDao.findById(targetId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "订单不存在"));
            boolean isRequester = reporterId.equals(order.getRequesterId());
            boolean isRunner = order.getRunnerId() != null && reporterId.equals(order.getRunnerId());
            if (!isRequester && !isRunner) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权举报该订单");
            }
            return;
        }

        if (targetType == ReportTargetType.USER) {
            User targetUser = userDao.findById(targetId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在"));
            if (targetUser.getId().equals(reporterId)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不能举报自己");
            }
            return;
        }

        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不支持的举报目标类型");
    }

    private ReportSummaryResponse toResponse(AdminReport report) {
        ReportSummaryResponse response = new ReportSummaryResponse();
        response.setId(report.getId());
        response.setCategory(report.getCategory());
        response.setTargetType(ReportTargetType.valueOf(report.getTargetType()));
        response.setTargetId(report.getTargetId());
        response.setStatus(report.getStatus());
        response.setCreatedAt(report.getCreatedAt());
        return response;
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
