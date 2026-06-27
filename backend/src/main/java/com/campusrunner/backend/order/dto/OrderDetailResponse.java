package com.campusrunner.backend.order.dto;

import java.time.LocalDateTime;
import java.util.List;

import com.campusrunner.backend.order.enums.CancelledBy;
import com.campusrunner.backend.order.enums.ContactMode;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;

import lombok.Data;

/**
 * 订单详情响应。
 */
@Data
public class OrderDetailResponse {

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
    private ContactMode contactMode;
    private String contactValue;
    private String remark;
    private OrderStatus status;
    private CancelledBy cancelledBy;
    private String cancelReason;
    private OrderCancelRequestResponse cancelRequest;
    private List<OrderDeliveryImageResponse> deliveryImages;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
