package com.campusrunner.backend.order.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campusrunner.backend.order.enums.OrderStatus;

import lombok.Data;

/**
 * 璁㈠崟鐘舵€佹祦杞棩蹇楀疄浣撱€? */
@Data
@TableName("order_status_logs")
public class OrderStatusLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long orderId;

    private OrderStatus fromStatus;

    private OrderStatus toStatus;

    private Long operatorId;

    private String note;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}

