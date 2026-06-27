package com.campusrunner.backend.order.dto;

import lombok.Data;

import java.util.List;

/**
 * 璁㈠崟鍒楄〃鍝嶅簲銆?
 */
@Data
public class OrderListResponse {
    private List<OrderSummaryResponse> list;
    private long total;
    private int page;
    private int pageSize;

}
