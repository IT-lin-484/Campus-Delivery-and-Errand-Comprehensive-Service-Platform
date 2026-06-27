package com.campusrunner.backend.conversation.dto;

import java.time.LocalDateTime;

import com.campusrunner.backend.conversation.entity.Conversation;
import com.campusrunner.backend.user.entity.User;

import lombok.Data;

/**
 * 会话摘要。
 */
@Data
public class ConversationSummaryResponse {
    private Long id;
    private String type = "PRIVATE";
    private String title;
    private String avatarUrl;
    private String lastMessagePreview;
    private LocalDateTime lastMessageAt;
    private int unreadCount;
    private int memberCount;
    private ConversationUserResponse counterpart;
    private Boolean friendConversation;
    private Boolean temporaryConversation;
    private Integer temporaryMessageLimit;
    private Integer temporaryMessageCount;
    private Integer temporaryMessageRemaining;
    private Boolean canSendMessage;

    public static ConversationSummaryResponse from(
            Conversation conversation,
            User counterpart,
            int unreadCount,
            boolean online,
            boolean friendConversation,
            int temporaryMessageLimit,
            int temporaryMessageCount,
            boolean canSendMessage) {
        ConversationSummaryResponse response = new ConversationSummaryResponse();
        response.setId(conversation.getId());
        response.setTitle(resolveTitle(counterpart));
        response.setAvatarUrl(counterpart == null ? null : counterpart.getAvatarUrl());
        response.setLastMessagePreview(conversation.getLastMessagePreview());
        response.setLastMessageAt(conversation.getLastMessageAt());
        response.setUnreadCount(unreadCount);
        response.setMemberCount(2);
        response.setCounterpart(counterpart == null ? null : ConversationUserResponse.fromEntity(counterpart, online));
        response.setFriendConversation(friendConversation);
        response.setTemporaryConversation(!friendConversation);
        response.setTemporaryMessageLimit(temporaryMessageLimit);
        response.setTemporaryMessageCount(temporaryMessageCount);
        response.setTemporaryMessageRemaining(Math.max(0, temporaryMessageLimit - temporaryMessageCount));
        response.setCanSendMessage(canSendMessage);
        return response;
    }

    private static String resolveTitle(User counterpart) {
        if (counterpart == null) {
            return "未知用户";
        }
        String nickname = counterpart.getNickname();
        if (nickname != null && !nickname.isBlank()) {
            return nickname.trim();
        }
        return counterpart.getUsername();
    }
}
