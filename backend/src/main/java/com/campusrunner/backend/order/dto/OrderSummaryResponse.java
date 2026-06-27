package com.campusrunner.backend.order.dto;

import java.time.LocalDateTime;

import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;

import lombok.Data;

/**
 * 订单列表项响应。
 */
@Data
public class OrderSummaryResponse {

    private Long id;
    private Long requesterId;
    private String requesterUsername;
    private String requesterNickname;
    private String requesterAvatarUrl;
    private Long runnerId;
    private OrderType type;
    private String pickupLocation;
    private String dropoffLocation;
    private LocalDateTime expectedTime;
    private Integer rewardAmount;
    private OrderStatus status;
    private LocalDateTime createdAt;
}
