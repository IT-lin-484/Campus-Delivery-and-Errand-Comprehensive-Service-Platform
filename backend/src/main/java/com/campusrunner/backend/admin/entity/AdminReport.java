package com.campusrunner.backend.admin.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campusrunner.backend.admin.enums.AdminReportStatus;

import lombok.Data;

/**
 * 涓炬姤/宸ュ崟瀹炰綋銆? */
@Data
@TableName("admin_reports")
public class AdminReport {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String category;

    private String targetType;

    private Long targetId;

    private Long reporterId;

    private String description;

    private AdminReportStatus status;

    private Long handledBy;

    private String handleNote;

    private LocalDateTime handledAt;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}

