package com.campusrunner.backend.order.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 璁㈠崟浜や粯鍥剧墖淇℃伅鍝嶅簲銆?
 */
@Data
public class OrderDeliveryImageResponse {

    private Long id;
    private Long orderId;
    private Long uploaderId;
    private String imageUrl;
    private String note;
    private LocalDateTime createdAt;

}
