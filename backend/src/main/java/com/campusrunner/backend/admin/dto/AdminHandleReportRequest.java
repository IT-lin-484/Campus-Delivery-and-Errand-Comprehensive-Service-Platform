package com.campusrunner.backend.admin.dto;

import com.campusrunner.backend.admin.enums.AdminReportStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 管理员处理举报请求。
 */
@Data
public class AdminHandleReportRequest {

    @NotNull(message = "处理状态不能为空")
    private AdminReportStatus status;

    @Size(max = 200, message = "处理说明长度不能超过 200 个字符")
    private String handleNote;
}
