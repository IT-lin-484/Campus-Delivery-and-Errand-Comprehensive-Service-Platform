package com.campusrunner.backend.admin.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * System configuration update request.
 */
@Data
public class AdminUpdateConfigRequest {

    @NotNull(message = "接单方取消窗口不能为空")
    @Min(value = 0, message = "接单方取消窗口不能小于 0")
    private Integer cancelWindowRunnerMinutes;

    @NotNull(message = "发单方取消窗口不能为空")
    @Min(value = 0, message = "发单方取消窗口不能小于 0")
    private Integer cancelWindowRequesterMinutes;

    @NotNull(message = "订单过期宽限时间不能为空")
    @Min(value = 0, message = "订单过期宽限时间不能小于 0")
    private Integer expireGraceMinutes;

    @NotNull(message = "最大并发订单数不能为空")
    @Min(value = 1, message = "最大并发订单数不能小于 1")
    private Integer maxConcurrentOrders;

    @NotNull(message = "每日最大接单数不能为空")
    @Min(value = 1, message = "每日最大接单数不能小于 1")
    private Integer maxDailyAccept;
}
