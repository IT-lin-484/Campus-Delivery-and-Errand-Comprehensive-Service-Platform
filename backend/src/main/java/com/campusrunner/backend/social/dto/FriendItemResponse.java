package com.campusrunner.backend.social.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 濂藉弸鍒楄〃椤广€?
 */
@Data
public class FriendItemResponse {
    private Long userId;
    private String username;
    private String nickname;
    private String avatarUrl;
    private String bio;
    private LocalDateTime becameFriendsAt;

}
