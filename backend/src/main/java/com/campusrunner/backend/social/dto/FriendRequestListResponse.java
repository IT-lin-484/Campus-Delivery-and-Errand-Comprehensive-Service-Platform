package com.campusrunner.backend.social.dto;

import lombok.Data;

import java.util.List;

/**
 * 濂藉弸鐢宠鍒楄〃鍝嶅簲銆?
 */
@Data
public class FriendRequestListResponse {
    private List<FriendRequestItemResponse> received;
    private List<FriendRequestItemResponse> sent;

}
