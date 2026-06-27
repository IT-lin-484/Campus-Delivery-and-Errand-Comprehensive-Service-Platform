package com.campusrunner.backend.admin.dto;

import com.campusrunner.backend.user.enums.UserStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 管理员修改用户状态请求。
 */
@Data
public class AdminUpdateUserStatusRequest {

    @NotNull(message = "用户状态不能为空")
    private UserStatus status;

    @Size(max = 200, message = "备注长度不能超过 200 个字符")
    private String note;
}
