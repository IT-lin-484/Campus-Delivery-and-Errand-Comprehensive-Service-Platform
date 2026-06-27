package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.util.List;

/**
 * 绠＄悊鍛樺璁℃棩蹇楀垪琛ㄥ搷搴斻€?
 */
@Data
public class AdminAuditLogListResponse {
    private List<AdminAuditLogResponse> list;
    private long total;
    private int page;
    private int pageSize;

}
