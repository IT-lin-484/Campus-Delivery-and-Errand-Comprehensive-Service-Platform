package com.campusrunner.backend.conversation.dto;

import java.time.LocalDateTime;

import com.campusrunner.backend.conversation.entity.ChatMessage;
import com.campusrunner.backend.user.entity.User;

import lombok.Data;

/**
 * 消息项。
 */
@Data
public class MessageItemResponse {
    private Long id;
    private Long conversationId;
    private ConversationUserResponse sender;
    private String clientMessageId;
    private String contentType;
    private String content;
    private String status;
    private LocalDateTime sentAt;
    private boolean mine;

    public static MessageItemResponse from(Long currentUserId, ChatMessage message, User sender, boolean online) {
        MessageItemResponse response = new MessageItemResponse();
        response.setId(message.getId());
        response.setConversationId(message.getConversationId());
        response.setSender(ConversationUserResponse.fromEntity(sender, online));
        response.setClientMessageId(message.getClientMessageId());
        response.setContentType(message.getContentType().name());
        response.setContent(message.getContent());
        response.setStatus(message.getStatus().name());
        response.setSentAt(message.getSentAt());
        response.setMine(sender.getId().equals(currentUserId));
        return response;
    }
}
