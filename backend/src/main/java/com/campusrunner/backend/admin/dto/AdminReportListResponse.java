package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.util.List;

/**
 * 涓炬姤/宸ュ崟鍒楄〃鍝嶅簲銆?
 */
@Data
public class AdminReportListResponse {
    private List<AdminReportSummaryResponse> list;
    private long total;
    private int page;
    private int pageSize;

}
