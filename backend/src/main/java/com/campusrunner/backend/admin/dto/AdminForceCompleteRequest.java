package com.campusrunner.backend.admin.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 管理员强制完成订单请求。
 */
@Data
public class AdminForceCompleteRequest {

    @Size(max = 200, message = "备注长度不能超过 200 个字符")
    private String note;
}
