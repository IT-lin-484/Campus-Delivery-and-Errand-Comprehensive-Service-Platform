package com.campusrunner.backend.order.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.order.enums.OrderCancelRequestStatus;

/**
 * 璁㈠崟鍙栨秷鐢宠淇℃伅鍝嶅簲銆?
 */
@Data
public class OrderCancelRequestResponse {

    private Long id;
    private Long orderId;
    private Long requesterId;
    private Long runnerId;
    private String reason;
    private OrderCancelRequestStatus status;
    private Long handledBy;
    private String handleNote;
    private LocalDateTime handledAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

}
