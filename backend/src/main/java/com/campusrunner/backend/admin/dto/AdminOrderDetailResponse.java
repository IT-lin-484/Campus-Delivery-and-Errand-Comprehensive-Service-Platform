package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

import com.campusrunner.backend.order.enums.CancelledBy;
import com.campusrunner.backend.order.enums.ContactMode;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;

/**
 * 绠＄悊鍛樼璁㈠崟璇︽儏鍝嶅簲銆?
 */
@Data
public class AdminOrderDetailResponse {
    private Long id;
    private Long requesterId;
    private String requesterUsername;
    private Long runnerId;
    private String runnerUsername;
    private OrderType type;
    private String pickupLocation;
    private String dropoffLocation;
    private LocalDateTime expectedTime;
    private Integer rewardAmount;
    private ContactMode contactMode;
    private String contactValueMasked;
    private String remark;
    private OrderStatus status;
    private CancelledBy cancelledBy;
    private String cancelReason;
    private boolean abnormalFlag;
    private String abnormalNote;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<AdminOrderStatusLogResponse> statusLogs;

}
