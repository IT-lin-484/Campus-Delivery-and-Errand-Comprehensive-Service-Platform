package com.campusrunner.backend.admin.service;

import com.campusrunner.backend.admin.dto.AdminOverviewResponse;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.admin.dao.AdminReportDao;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.user.dao.UserDao;

public interface AdminOverviewService {
    AdminOverviewResponse getOverview();
}

