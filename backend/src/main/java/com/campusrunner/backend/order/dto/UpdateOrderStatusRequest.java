package com.campusrunner.backend.order.dto;

import com.campusrunner.backend.order.enums.OrderStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 骑手更新订单状态请求。
 */
@Data
public class UpdateOrderStatusRequest {

    @NotNull(message = "目标状态不能为空")
    private OrderStatus toStatus;

    @Size(max = 200, message = "备注长度不能超过 200 个字符")
    private String note;
}
