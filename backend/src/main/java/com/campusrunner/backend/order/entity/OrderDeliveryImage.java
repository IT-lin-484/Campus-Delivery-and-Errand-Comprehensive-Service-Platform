package com.campusrunner.backend.order.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import lombok.Data;

/**
 * 璁㈠崟浜や粯鍥剧墖瀹炰綋銆? */
@Data
@TableName("order_delivery_images")
public class OrderDeliveryImage {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long orderId;

    private Long uploaderId;

    private String imageUrl;

    private String note;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}

