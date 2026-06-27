package com.campusrunner.backend.conversation.dto;

import com.campusrunner.backend.user.entity.User;

import lombok.Data;

/**
 * 聊天页用户摘要。
 */
@Data
public class ConversationUserResponse {
    private Long id;
    private String username;
    private String nickname;
    private String avatarUrl;
    private Boolean online;

    public static ConversationUserResponse fromEntity(User user, boolean online) {
        ConversationUserResponse response = new ConversationUserResponse();
        response.setId(user.getId());
        response.setUsername(user.getUsername());
        response.setNickname(user.getNickname());
        response.setAvatarUrl(user.getAvatarUrl());
        response.setOnline(online);
        return response;
    }
}
