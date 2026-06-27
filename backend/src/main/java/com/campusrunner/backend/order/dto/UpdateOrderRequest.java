package com.campusrunner.backend.order.dto;

import java.time.LocalDateTime;

import com.campusrunner.backend.order.enums.ContactMode;
import com.campusrunner.backend.order.enums.OrderType;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 修改订单请求。
 */
@Data
public class UpdateOrderRequest {

    @NotNull(message = "订单分类不能为空")
    private OrderType type;

    @NotBlank(message = "取件地点不能为空")
    @Size(max = 120, message = "取件地点长度不能超过 120 个字符")
    private String pickupLocation;

    @NotBlank(message = "送达地点不能为空")
    @Size(max = 120, message = "送达地点长度不能超过 120 个字符")
    private String dropoffLocation;

    @NotNull(message = "期望完成时间不能为空")
    private LocalDateTime expectedTime;

    @NotNull(message = "赏金不能为空")
    @Min(value = 1, message = "赏金不能小于 1")
    @Max(value = 50, message = "赏金不能超过 50")
    private Integer rewardAmount;

    @NotNull(message = "联系形式不能为空")
    private ContactMode contactMode;

    @Size(max = 64, message = "联系方式内容长度不能超过 64 个字符")
    private String contactValue;

    @Size(max = 200, message = "备注长度不能超过 200 个字符")
    private String remark;
}
