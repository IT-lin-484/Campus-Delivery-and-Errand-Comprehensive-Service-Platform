package com.campusrunner.backend.profile.dto;

import lombok.Data;

/**
 * 鐢ㄦ埛涓婚〉锛堜粬浜鸿瑙掞級鍝嶅簲銆?
 */
@Data
public class UserProfileResponse {
    private Long id;
    private String username;
    private String nickname;
    private String avatarUrl;
    private String bio;
    private UserRelationStatus relationStatus;
    private Boolean canSendFriendRequest;
    private Long totalPublishedOrders;
    private Long totalAcceptedOrders;

}
