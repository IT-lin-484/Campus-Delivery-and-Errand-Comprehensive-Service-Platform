package com.campusrunner.backend.order.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campusrunner.backend.order.enums.CancelledBy;
import com.campusrunner.backend.order.enums.ContactMode;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;

import lombok.Data;

/**
 * 璁㈠崟瀹炰綋銆? */
@Data
@TableName("orders")
public class Order {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long requesterId;

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

    private boolean abnormalFlag;

    private String abnormalNote;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}

