package com.campusrunner.backend.social.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.social.enums.FriendRequestStatus;

/**
 * 濂藉弸鐢宠鏄庣粏銆?
 */
@Data
public class FriendRequestItemResponse {
    private Long id;
    private Long fromUserId;
    private String fromNickname;
    private String fromAvatarUrl;
    private Long toUserId;
    private String toNickname;
    private String toAvatarUrl;
    private FriendRequestStatus status;
    private String message;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

}
