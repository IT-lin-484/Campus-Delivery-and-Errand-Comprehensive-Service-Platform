package com.campusrunner.backend.admin.service.impl;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.admin.dto.AdminForceCancelRequest;
import com.campusrunner.backend.admin.dto.AdminForceCompleteRequest;
import com.campusrunner.backend.admin.dto.AdminMarkExceptionRequest;
import com.campusrunner.backend.admin.dto.AdminOrderDetailResponse;
import com.campusrunner.backend.admin.dto.AdminOrderListResponse;
import com.campusrunner.backend.admin.dto.AdminOrderStatusLogResponse;
import com.campusrunner.backend.admin.dto.AdminOrderSummaryResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.service.AdminOrderService;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.order.dao.OrderStatusLogDao;
import com.campusrunner.backend.order.entity.Order;
import com.campusrunner.backend.order.entity.OrderStatusLog;
import com.campusrunner.backend.order.enums.CancelledBy;
import com.campusrunner.backend.order.enums.ContactMode;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;

/**
 * 管理员订单管理服务实现。
 */
@Service
public class AdminOrderServiceImpl implements AdminOrderService {

    private static final Set<OrderStatus> FINAL_STATUSES = EnumSet.of(
            OrderStatus.COMPLETED,
            OrderStatus.CANCELLED,
            OrderStatus.EXPIRED);

    private final OrderDao orderDao;
    private final OrderStatusLogDao orderStatusLogDao;
    private final AdminAuditLogDao adminAuditLogDao;
    private final UserDao userDao;

    public AdminOrderServiceImpl(
            OrderDao orderDao,
            OrderStatusLogDao orderStatusLogDao,
            AdminAuditLogDao adminAuditLogDao,
            UserDao userDao) {
        this.orderDao = orderDao;
        this.orderStatusLogDao = orderStatusLogDao;
        this.adminAuditLogDao = adminAuditLogDao;
        this.userDao = userDao;
    }

    @Override
    @Transactional(readOnly = true)
    public AdminOrderListResponse listOrders(
            OrderStatus status,
            OrderType type,
            String keyword,
            String startTime,
            String endTime,
            Boolean isAbnormal,
            int page,
            int pageSize) {
        LocalDateTime parsedStartTime = parseDateTime(startTime, "start_time");
        LocalDateTime parsedEndTime = parseDateTime(endTime, "end_time");
        if (parsedStartTime != null && parsedEndTime != null && parsedStartTime.isAfter(parsedEndTime)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "start_time 不能晚于 end_time");
        }

        Page<Order> result = orderDao.selectPage(
                new Page<>(page, pageSize),
                buildQueryWrapper(status, type, keyword, parsedStartTime, parsedEndTime, isAbnormal));
        Map<Long, User> usersById = loadUsers(result.getRecords());

        List<AdminOrderSummaryResponse> list = result.getRecords().stream()
                .map(order -> toSummary(order, usersById))
                .toList();

        AdminOrderListResponse response = new AdminOrderListResponse();
        response.setList(list);
        response.setTotal(result.getTotal());
        response.setPage(page);
        response.setPageSize(pageSize);
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public AdminOrderDetailResponse getOrderDetail(Long orderId) {
        Order order = findOrder(orderId);
        return toDetail(order, loadUsers(List.of(order)));
    }

    @Override
    @Transactional
    public AdminOrderDetailResponse forceCancel(
            Long orderId,
            Long adminId,
            String reason,
            String ip,
            String deviceId) {
        Order order = findOrder(orderId);
        ensureNotFinal(order.getStatus(), "当前订单已结束，不能再次强制取消");

        String normalizedReason = normalizeText(reason);
        if (normalizedReason == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "取消原因不能为空");
        }

        String beforeData = snapshot(order);
        OrderStatus fromStatus = order.getStatus();
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledBy(CancelledBy.ADMIN);
        order.setCancelReason(normalizedReason);
        Order saved = orderDao.save(order);

        writeStatusLog(saved.getId(), fromStatus, OrderStatus.CANCELLED, adminId, "管理员强制取消订单：" + normalizedReason);
        writeAuditLog(
                adminId,
                "ORDER_FORCE_CANCEL",
                saved.getId(),
                beforeData,
                snapshot(saved),
                ip,
                deviceId,
                normalizedReason);
        return toDetail(saved, loadUsers(List.of(saved)));
    }

    @Override
    @Transactional
    public AdminOrderDetailResponse forceComplete(
            Long orderId,
            Long adminId,
            String note,
            String ip,
            String deviceId) {
        Order order = findOrder(orderId);
        if (FINAL_STATUSES.contains(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "当前订单已结束，不能再次强制完成");
        }

        String normalizedNote = normalizeText(note);
        String beforeData = snapshot(order);
        OrderStatus fromStatus = order.getStatus();
        order.setStatus(OrderStatus.COMPLETED);
        order.setCancelledBy(null);
        order.setCancelReason(null);
        Order saved = orderDao.save(order);

        String statusNote = normalizedNote == null
                ? "管理员强制完成订单"
                : "管理员强制完成订单：" + normalizedNote;
        writeStatusLog(saved.getId(), fromStatus, OrderStatus.COMPLETED, adminId, statusNote);
        writeAuditLog(
                adminId,
                "ORDER_FORCE_COMPLETE",
                saved.getId(),
                beforeData,
                snapshot(saved),
                ip,
                deviceId,
                statusNote);
        return toDetail(saved, loadUsers(List.of(saved)));
    }

    @Override
    @Transactional
    public AdminOrderDetailResponse markException(
            Long orderId,
            Long adminId,
            String note,
            String ip,
            String deviceId) {
        Order order = findOrder(orderId);
        String normalizedNote = normalizeText(note);
        if (normalizedNote == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "异常说明不能为空");
        }

        String beforeData = snapshot(order);
        order.setAbnormalFlag(true);
        order.setAbnormalNote(normalizedNote);
        Order saved = orderDao.save(order);

        writeStatusLog(saved.getId(), saved.getStatus(), saved.getStatus(), adminId, "管理员标记订单异常：" + normalizedNote);
        writeAuditLog(
                adminId,
                "ORDER_MARK_EXCEPTION",
                saved.getId(),
                beforeData,
                snapshot(saved),
                ip,
                deviceId,
                normalizedNote);
        return toDetail(saved, loadUsers(List.of(saved)));
    }

    @Override
    @Transactional
    public AdminOrderDetailResponse forceCancel(
            Long orderId,
            Long adminId,
            AdminForceCancelRequest request,
            String ip,
            String deviceId) {
        return forceCancel(orderId, adminId, request == null ? null : request.getReason(), ip, deviceId);
    }

    @Override
    @Transactional
    public AdminOrderDetailResponse forceComplete(
            Long orderId,
            Long adminId,
            AdminForceCompleteRequest request,
            String ip,
            String deviceId) {
        return forceComplete(orderId, adminId, request == null ? null : request.getNote(), ip, deviceId);
    }

    @Override
    @Transactional
    public AdminOrderDetailResponse markException(
            Long orderId,
            Long adminId,
            AdminMarkExceptionRequest request,
            String ip,
            String deviceId) {
        return markException(orderId, adminId, request == null ? null : request.getNote(), ip, deviceId);
    }

    private LambdaQueryWrapper<Order> buildQueryWrapper(
            OrderStatus status,
            OrderType type,
            String keyword,
            LocalDateTime startTime,
            LocalDateTime endTime,
            Boolean isAbnormal) {
        LambdaQueryWrapper<Order> wrapper = Wrappers.lambdaQuery();
        if (status != null) {
            wrapper.eq(Order::getStatus, status);
        }
        if (type != null) {
            wrapper.eq(Order::getType, type);
        }
        if (isAbnormal != null) {
            wrapper.eq(Order::isAbnormalFlag, isAbnormal);
        }
        if (keyword != null && !keyword.isBlank()) {
            String normalizedKeyword = keyword.trim();
            wrapper.and(group -> group.like(Order::getPickupLocation, normalizedKeyword)
                    .or()
                    .like(Order::getDropoffLocation, normalizedKeyword)
                    .or()
                    .like(Order::getRemark, normalizedKeyword)
                    .or()
                    .like(Order::getContactValue, normalizedKeyword));
        }
        if (startTime != null) {
            wrapper.ge(Order::getExpectedTime, startTime);
        }
        if (endTime != null) {
            wrapper.le(Order::getExpectedTime, endTime);
        }
        wrapper.orderByDesc(Order::getCreatedAt);
        return wrapper;
    }

    private Order findOrder(Long orderId) {
        return orderDao.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "订单不存在"));
    }

    private void ensureNotFinal(OrderStatus currentStatus, String message) {
        if (FINAL_STATUSES.contains(currentStatus)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        }
    }

    private void writeStatusLog(Long orderId, OrderStatus fromStatus, OrderStatus toStatus, Long operatorId, String note) {
        OrderStatusLog log = new OrderStatusLog();
        log.setOrderId(orderId);
        log.setFromStatus(fromStatus);
        log.setToStatus(toStatus);
        log.setOperatorId(operatorId);
        log.setNote(note);
        orderStatusLogDao.save(log);
    }

    private void writeAuditLog(
            Long operatorId,
            String action,
            Long targetId,
            String beforeData,
            String afterData,
            String ip,
            String deviceId,
            String note) {
        AdminAuditLog log = new AdminAuditLog();
        log.setOperatorId(operatorId);
        log.setAction(action);
        log.setTargetType("ORDER");
        log.setTargetId(targetId);
        log.setBeforeData(beforeData);
        log.setAfterData(afterData);
        log.setIp(ip);
        log.setDeviceId(normalizeText(deviceId));
        log.setNote(note);
        adminAuditLogDao.save(log);
    }

    private AdminOrderSummaryResponse toSummary(Order order, Map<Long, User> usersById) {
        AdminOrderSummaryResponse response = new AdminOrderSummaryResponse();
        response.setId(order.getId());
        response.setType(order.getType());
        response.setPickupLocation(order.getPickupLocation());
        response.setDropoffLocation(order.getDropoffLocation());
        response.setExpectedTime(order.getExpectedTime());
        response.setRewardAmount(order.getRewardAmount());
        response.setStatus(order.getStatus());
        response.setRequesterId(order.getRequesterId());
        response.setRequesterUsername(resolveUsername(usersById, order.getRequesterId()));
        response.setRunnerId(order.getRunnerId());
        response.setRunnerUsername(resolveUsername(usersById, order.getRunnerId()));
        response.setContactValueMasked(maskContactValue(order.getContactMode(), order.getContactValue()));
        response.setAbnormalFlag(order.isAbnormalFlag());
        response.setCreatedAt(order.getCreatedAt());
        return response;
    }

    private AdminOrderDetailResponse toDetail(Order order, Map<Long, User> usersById) {
        AdminOrderDetailResponse response = new AdminOrderDetailResponse();
        response.setId(order.getId());
        response.setRequesterId(order.getRequesterId());
        response.setRequesterUsername(resolveUsername(usersById, order.getRequesterId()));
        response.setRunnerId(order.getRunnerId());
        response.setRunnerUsername(resolveUsername(usersById, order.getRunnerId()));
        response.setType(order.getType());
        response.setPickupLocation(order.getPickupLocation());
        response.setDropoffLocation(order.getDropoffLocation());
        response.setExpectedTime(order.getExpectedTime());
        response.setRewardAmount(order.getRewardAmount());
        response.setContactMode(order.getContactMode());
        response.setContactValueMasked(maskContactValue(order.getContactMode(), order.getContactValue()));
        response.setRemark(order.getRemark());
        response.setStatus(order.getStatus());
        response.setCancelledBy(order.getCancelledBy());
        response.setCancelReason(order.getCancelReason());
        response.setAbnormalFlag(order.isAbnormalFlag());
        response.setAbnormalNote(order.getAbnormalNote());
        response.setCreatedAt(order.getCreatedAt());
        response.setUpdatedAt(order.getUpdatedAt());
        response.setStatusLogs(orderStatusLogDao.findByOrderIdOrderByCreatedAtDesc(order.getId()).stream()
                .map(this::toStatusLog)
                .toList());
        return response;
    }

    private Map<Long, User> loadUsers(List<Order> orders) {
        Set<Long> userIds = orders.stream()
                .flatMap(order -> Stream.of(order.getRequesterId(), order.getRunnerId()))
                .filter(id -> id != null)
                .collect(Collectors.toSet());
        if (userIds.isEmpty()) {
            return Map.of();
        }
        return userDao.findAllById(userIds).stream()
                .collect(Collectors.toMap(User::getId, user -> user));
    }

    private String resolveUsername(Map<Long, User> usersById, Long userId) {
        if (userId == null) {
            return null;
        }
        User user = usersById.get(userId);
        return user == null ? null : user.getUsername();
    }

    private AdminOrderStatusLogResponse toStatusLog(OrderStatusLog log) {
        AdminOrderStatusLogResponse response = new AdminOrderStatusLogResponse();
        response.setId(log.getId());
        response.setFromStatus(log.getFromStatus());
        response.setToStatus(log.getToStatus());
        response.setOperatorId(log.getOperatorId());
        response.setNote(log.getNote());
        response.setCreatedAt(log.getCreatedAt());
        return response;
    }

    private String maskContactValue(ContactMode contactMode, String contactValue) {
        if (contactMode != ContactMode.PHONE || contactValue == null || contactValue.isBlank()) {
            return "-";
        }
        String phone = contactValue.trim();
        if (phone.length() < 7) {
            return "****";
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    private String normalizeText(String value) {
        if (value == null) {
            return null;
        }
        String normalized = value.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(value.trim());
        } catch (DateTimeParseException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, fieldName + " 必须是 ISO 格式的时间字符串");
        }
    }

    private String snapshot(Order order) {
        String cancelledBy = order.getCancelledBy() == null ? null : order.getCancelledBy().name();
        String status = order.getStatus() == null ? null : order.getStatus().name();
        return "{"
                + "\"status\":" + quote(status) + ","
                + "\"cancelledBy\":" + quote(cancelledBy) + ","
                + "\"cancelReason\":" + quote(order.getCancelReason()) + ","
                + "\"abnormalFlag\":" + order.isAbnormalFlag() + ","
                + "\"abnormalNote\":" + quote(order.getAbnormalNote())
                + "}";
    }

    private String quote(String value) {
        if (value == null) {
            return "null";
        }
        return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }
}
