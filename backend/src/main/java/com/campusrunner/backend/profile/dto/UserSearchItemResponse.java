package com.campusrunner.backend.profile.dto;

import lombok.Data;

/**
 * 鐢ㄦ埛鎼滅储缁撴灉椤广€?
 */
@Data
public class UserSearchItemResponse {
    private Long id;
    private String username;
    private String nickname;
    private String avatarUrl;
    private UserRelationStatus relationStatus;
    private Boolean canSendFriendRequest;

}
