package com.campusrunner.backend.conversation.service;

import java.util.List;

import com.campusrunner.backend.conversation.dto.ConversationSummaryResponse;
import com.campusrunner.backend.conversation.dto.MessageItemResponse;
import com.campusrunner.backend.conversation.dto.MessageListResponse;
import com.campusrunner.backend.conversation.dto.RealtimeMessageDispatchResult;
import com.campusrunner.backend.conversation.dto.SendMessageRequest;

/**
 * Conversation service.
 */
public interface ConversationService {

    List<ConversationSummaryResponse> listConversations(Long currentUserId);

    ConversationSummaryResponse createOrGetConversation(Long currentUserId, Long targetUserId, Long orderId);

    MessageListResponse listMessages(Long currentUserId, Long conversationId, int page, int pageSize);

    MessageItemResponse sendMessage(Long currentUserId, Long conversationId, SendMessageRequest request);

    MessageItemResponse sendTextMessage(Long currentUserId, Long conversationId, SendMessageRequest request);

    RealtimeMessageDispatchResult sendTextMessageByRealtime(Long currentUserId, Long conversationId, SendMessageRequest request);

    MessageItemResponse sendImageMessage(Long currentUserId, Long conversationId, String imageUrl);

    void markConversationRead(Long currentUserId, Long conversationId);

    long countTotalUnreadMessages(Long currentUserId);

    void ensureConversationBetweenUsers(Long userAId, Long userBId);

    void sendOrderImageMessage(Long senderId, Long receiverId, Long orderId, String imageUrl, String note);

    void deleteConversation(Long currentUserId, Long conversationId);

    void deleteMessage(Long currentUserId, Long conversationId, Long messageId);
}
