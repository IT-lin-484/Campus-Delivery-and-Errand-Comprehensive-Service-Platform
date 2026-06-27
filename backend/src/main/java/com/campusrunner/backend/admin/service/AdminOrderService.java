package com.campusrunner.backend.admin.service;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dto.AdminForceCancelRequest;
import com.campusrunner.backend.admin.dto.AdminForceCompleteRequest;
import com.campusrunner.backend.admin.dto.AdminMarkExceptionRequest;
import com.campusrunner.backend.admin.dto.AdminOrderDetailResponse;
import com.campusrunner.backend.admin.dto.AdminOrderListResponse;
import com.campusrunner.backend.admin.dto.AdminOrderStatusLogResponse;
import com.campusrunner.backend.admin.dto.AdminOrderSummaryResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.order.entity.Order;
import com.campusrunner.backend.order.entity.OrderStatusLog;
import com.campusrunner.backend.order.enums.CancelledBy;
import com.campusrunner.backend.order.enums.ContactMode;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.order.dao.OrderStatusLogDao;

public interface AdminOrderService {
    AdminOrderListResponse listOrders(OrderStatus status, OrderType type, String keyword, String startTime, String endTime, Boolean isAbnormal, int page, int pageSize);
    AdminOrderDetailResponse getOrderDetail(Long orderId);
    AdminOrderDetailResponse forceCancel(Long orderId, Long adminId, String reason, String ip, String deviceId);
    AdminOrderDetailResponse forceComplete(Long orderId, Long adminId, String note, String ip, String deviceId);
    AdminOrderDetailResponse markException(Long orderId, Long adminId, String note, String ip, String deviceId);
    AdminOrderDetailResponse forceCancel(Long orderId, Long adminId, AdminForceCancelRequest request, String ip, String deviceId);
    AdminOrderDetailResponse forceComplete(Long orderId, Long adminId, AdminForceCompleteRequest request, String ip, String deviceId);
    AdminOrderDetailResponse markException(Long orderId, Long adminId, AdminMarkExceptionRequest request, String ip, String deviceId);
}

