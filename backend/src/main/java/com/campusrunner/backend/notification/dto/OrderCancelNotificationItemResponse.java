package com.campusrunner.backend.notification.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.order.enums.OrderCancelRequestStatus;

/**
 * 璁㈠崟鍙栨秷鐩稿叧閫氱煡椤广€?
 */
@Data
public class OrderCancelNotificationItemResponse {
    private Long cancelRequestId;
    private Long orderId;
    private String notificationType;
    private String title;
    private String content;
    private OrderCancelRequestStatus status;
    private Boolean unread;
    private LocalDateTime eventTime;

}
