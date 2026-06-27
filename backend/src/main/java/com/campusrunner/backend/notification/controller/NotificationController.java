package com.campusrunner.backend.notification.controller;

import java.util.List;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.auth.service.CurrentUserService;
import com.campusrunner.backend.notification.dto.OrderCancelNotificationItemResponse;
import com.campusrunner.backend.notification.dto.UnreadNotificationSummaryResponse;
import com.campusrunner.backend.notification.service.NotificationService;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 娑堟伅鏈涓庨€氱煡涓績鎺ュ彛銆? */
@Validated
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final CurrentUserService currentUserService;
    private final NotificationService notificationService;

    public NotificationController(CurrentUserService currentUserService, NotificationService notificationService) {
        this.currentUserService = currentUserService;
        this.notificationService = notificationService;
    }

    @GetMapping("/unread-summary")
    public UnreadNotificationSummaryResponse getUnreadSummary(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return notificationService.getUnreadSummary(currentUserId);
    }

    @GetMapping("/order-cancel")
    public List<OrderCancelNotificationItemResponse> listOrderCancelNotifications(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestParam(value = "limit", defaultValue = "20") @Min(1) @Max(50) int limit) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return notificationService.listOrderCancelNotifications(currentUserId, limit);
    }

    @PostMapping("/order-cancel/read-all")
    public UnreadNotificationSummaryResponse markOrderCancelNotificationsRead(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return notificationService.markOrderCancelNotificationsRead(currentUserId);
    }
}

