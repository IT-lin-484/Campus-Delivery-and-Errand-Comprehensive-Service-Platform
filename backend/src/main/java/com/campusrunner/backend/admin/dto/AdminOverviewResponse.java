package com.campusrunner.backend.admin.dto;

import lombok.Data;

/**
 * 绠＄悊绔瑙堝搷搴斻€?
 */
@Data
public class AdminOverviewResponse {
    private long totalOrders;
    private long openOrders;
    private long abnormalOrders;
    private long pendingReports;
    private long bannedUsers;

}
