package com.campusrunner.backend.admin.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.admin.dto.AdminForceCancelRequest;
import com.campusrunner.backend.admin.dto.AdminForceCompleteRequest;
import com.campusrunner.backend.admin.dto.AdminMarkExceptionRequest;
import com.campusrunner.backend.admin.dto.AdminOrderDetailResponse;
import com.campusrunner.backend.admin.dto.AdminOrderListResponse;
import com.campusrunner.backend.admin.service.AdminOrderService;
import com.campusrunner.backend.admin.service.AdminPermissionService;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;
import com.campusrunner.backend.user.entity.User;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 绠＄悊鍛樿鍗曠鐞嗘帴鍙ｃ€? */
@Validated
@RestController
@RequestMapping("/api/v1/admin/orders")
public class AdminOrderController {

    private final AdminPermissionService adminPermissionService;
    private final AdminOrderService adminOrderService;

    public AdminOrderController(AdminPermissionService adminPermissionService, AdminOrderService adminOrderService) {
        this.adminPermissionService = adminPermissionService;
        this.adminOrderService = adminOrderService;
    }

    @GetMapping
    public AdminOrderListResponse listOrders(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestParam(value = "status", required = false) OrderStatus status,
            @RequestParam(value = "type", required = false) OrderType type,
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "start_time", required = false) String startTime,
            @RequestParam(value = "end_time", required = false) String endTime,
            @RequestParam(value = "is_abnormal", required = false) Boolean isAbnormal,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "10") @Min(1) @Max(100) int pageSize) {
        adminPermissionService.requireAdmin(authorizationHeader);
        return adminOrderService.listOrders(status, type, keyword, startTime, endTime, isAbnormal, page, pageSize);
    }

    @GetMapping("/{id}")
    public AdminOrderDetailResponse getOrderDetail(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable("id") Long id) {
        adminPermissionService.requireAdmin(authorizationHeader);
        return adminOrderService.getOrderDetail(id);
    }

    @PostMapping("/{id}/force-cancel")
    public AdminOrderDetailResponse forceCancel(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable("id") Long id,
            @Valid @RequestBody AdminForceCancelRequest request,
            HttpServletRequest httpServletRequest) {
        User adminUser = adminPermissionService.requireAdmin(authorizationHeader);
        return adminOrderService.forceCancel(
                id,
                adminUser.getId(),
                request,
                extractClientIp(httpServletRequest),
                httpServletRequest.getHeader("X-Device-Id"));
    }

    @PostMapping("/{id}/force-complete")
    public AdminOrderDetailResponse forceComplete(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable("id") Long id,
            @Valid @RequestBody AdminForceCompleteRequest request,
            HttpServletRequest httpServletRequest) {
        User adminUser = adminPermissionService.requireAdmin(authorizationHeader);
        return adminOrderService.forceComplete(
                id,
                adminUser.getId(),
                request,
                extractClientIp(httpServletRequest),
                httpServletRequest.getHeader("X-Device-Id"));
    }

    @PostMapping("/{id}/mark-exception")
    public AdminOrderDetailResponse markException(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable("id") Long id,
            @Valid @RequestBody AdminMarkExceptionRequest request,
            HttpServletRequest httpServletRequest) {
        User adminUser = adminPermissionService.requireAdmin(authorizationHeader);
        return adminOrderService.markException(
                id,
                adminUser.getId(),
                request,
                extractClientIp(httpServletRequest),
                httpServletRequest.getHeader("X-Device-Id"));
    }

    private String extractClientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}

