package com.campusrunner.backend.admin.service.impl;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campusrunner.backend.admin.dto.AdminOverviewResponse;
import com.campusrunner.backend.admin.enums.AdminReportStatus;
import com.campusrunner.backend.admin.dao.AdminReportDao;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.user.dao.UserDao;

/**
 * 绠＄悊绔瑙堢粺璁℃湇鍔°€? */
@Service
public class AdminOverviewServiceImpl implements com.campusrunner.backend.admin.service.AdminOverviewService {

    private final OrderDao orderDao;
    private final AdminReportDao adminReportDao;
    private final UserDao userDao;

    public AdminOverviewServiceImpl(
            OrderDao orderDao,
            AdminReportDao adminReportDao,
            UserDao userDao) {
        this.orderDao = orderDao;
        this.adminReportDao = adminReportDao;
        this.userDao = userDao;
    }

    @Transactional(readOnly = true)
    public AdminOverviewResponse getOverview() {
        AdminOverviewResponse response = new AdminOverviewResponse();
        response.setTotalOrders(orderDao.count());
        response.setOpenOrders(orderDao.countByStatus(OrderStatus.OPEN));
        response.setAbnormalOrders(orderDao.countByAbnormalFlagTrue());
        response.setPendingReports(adminReportDao.countByStatus(AdminReportStatus.OPEN));
        response.setBannedUsers(userDao.countByStatus(UserStatus.BANNED));
        return response;
    }
}

