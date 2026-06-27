package com.campusrunner.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 管理员标记异常请求。
 */
@Data
public class AdminMarkExceptionRequest {

    @NotBlank(message = "异常说明不能为空")
    @Size(max = 200, message = "异常说明长度不能超过 200 个字符")
    private String note;
}
