package com.campusrunner.backend.admin.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import lombok.Data;

/**
 * 绠＄悊鍛樻搷浣滃璁℃棩蹇楀疄浣撱€? */
@Data
@TableName("admin_audit_log")
public class AdminAuditLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long operatorId;

    private String action;

    private String targetType;

    private Long targetId;

    private String beforeData;

    private String afterData;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime timestamp;

    private String ip;

    private String deviceId;

    private String note;
}

