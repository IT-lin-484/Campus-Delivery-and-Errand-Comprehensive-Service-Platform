package com.campusrunner.backend.profile.dto;

import lombok.Data;

/**
 * 鎴戠殑璧勬枡鍝嶅簲銆?
 */
@Data
public class MyProfileResponse {
    private Long id;
    private String username;
    private String nickname;
    private String phone;
    private String avatarUrl;
    private String commonAddress;
    private String bio;
    private Boolean allowFriendRequest;
    private Boolean allowSearch;
    private Boolean messageDnd;
    private Long totalPublishedOrders;
    private Long totalAcceptedOrders;

}
