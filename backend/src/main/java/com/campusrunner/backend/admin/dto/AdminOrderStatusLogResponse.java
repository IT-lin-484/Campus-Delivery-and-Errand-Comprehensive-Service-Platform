package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.order.enums.OrderStatus;

/**
 * 绠＄悊鍛樼璁㈠崟鐘舵€佹棩蹇楀搷搴斻€?
 */
@Data
public class AdminOrderStatusLogResponse {
    private Long id;
    private OrderStatus fromStatus;
    private OrderStatus toStatus;
    private Long operatorId;
    private String note;
    private LocalDateTime createdAt;

}
