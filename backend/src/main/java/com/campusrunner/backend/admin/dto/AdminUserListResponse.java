package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.util.List;

/**
 * 绠＄悊鍛樼敤鎴峰垪琛ㄥ搷搴斻€?
 */
@Data
public class AdminUserListResponse {
    private List<AdminUserSummaryResponse> list;
    private long total;
    private int page;
    private int pageSize;

}
