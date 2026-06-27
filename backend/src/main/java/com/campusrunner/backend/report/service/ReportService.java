package com.campusrunner.backend.report.service;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.campusrunner.backend.admin.entity.AdminReport;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.admin.dao.AdminReportDao;
import com.campusrunner.backend.order.entity.Order;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.report.dto.CreateReportRequest;
import com.campusrunner.backend.report.dto.ReportSummaryResponse;
import com.campusrunner.backend.report.enums.ReportTargetType;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.dao.UserDao;

public interface ReportService {
    ReportSummaryResponse createReport(Long reporterId, CreateReportRequest request);
}

