package com.campusrunner.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 管理员强制取消订单请求。
 */
@Data
public class AdminForceCancelRequest {

    @NotBlank(message = "取消原因不能为空")
    @Size(max = 200, message = "取消原因长度不能超过 200 个字符")
    private String reason;
}
