package com.campusrunner.backend.order.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.FieldStrategy;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campusrunner.backend.order.enums.OrderCancelRequestStatus;

import lombok.Data;

/**
 * 璁㈠崟鍙栨秷鐢宠瀹炰綋銆? */
@Data
@TableName("order_cancel_requests")
public class OrderCancelRequest {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long orderId;

    private Long requesterId;

    private Long runnerId;

    private String reason;

    private OrderCancelRequestStatus status;

    private Long handledBy;

    private String handleNote;

    private LocalDateTime handledAt;

    @TableField(updateStrategy = FieldStrategy.ALWAYS)
    private LocalDateTime requesterReadAt;

    private LocalDateTime runnerReadAt;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}

