package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 绯荤粺閰嶇疆鍝嶅簲銆?
 */
@Data
public class AdminConfigResponse {
    private Long id;
    private Integer cancelWindowRunnerMinutes;
    private Integer cancelWindowRequesterMinutes;
    private Integer expireGraceMinutes;
    private Integer maxConcurrentOrders;
    private Integer maxDailyAccept;
    private LocalDateTime updatedAt;

}
