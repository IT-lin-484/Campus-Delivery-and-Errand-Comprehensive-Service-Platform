package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.util.List;

/**
 * 绠＄悊鍛樼璁㈠崟鍒楄〃鍝嶅簲銆?
 */
@Data
public class AdminOrderListResponse {
    private List<AdminOrderSummaryResponse> list;
    private long total;
    private int page;
    private int pageSize;

}
