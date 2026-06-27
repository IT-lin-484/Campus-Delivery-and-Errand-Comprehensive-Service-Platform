package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;

/**
 * 绠＄悊鍛樼璁㈠崟鍒楄〃椤瑰搷搴斻€?
 */
@Data
public class AdminOrderSummaryResponse {
    private Long id;
    private OrderType type;
    private String pickupLocation;
    private String dropoffLocation;
    private LocalDateTime expectedTime;
    private Integer rewardAmount;
    private OrderStatus status;
    private Long requesterId;
    private String requesterUsername;
    private Long runnerId;
    private String runnerUsername;
    private String contactValueMasked;
    private boolean abnormalFlag;
    private LocalDateTime createdAt;

}
