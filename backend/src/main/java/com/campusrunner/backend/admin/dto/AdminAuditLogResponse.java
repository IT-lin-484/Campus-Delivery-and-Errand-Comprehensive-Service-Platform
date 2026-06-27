package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 绠＄悊鍛樺璁℃棩蹇楅」銆?
 */
@Data
public class AdminAuditLogResponse {
    private Long id;
    private Long operatorId;
    private String action;
    private String targetType;
    private Long targetId;
    private String note;
    private String ip;
    private String deviceId;
    private LocalDateTime timestamp;

}
