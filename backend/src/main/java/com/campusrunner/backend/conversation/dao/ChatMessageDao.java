package com.campusrunner.backend.conversation.dao;

import java.util.Optional;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.conversation.entity.ChatMessage;

/**
 * 消息 DAO。
 */
public interface ChatMessageDao extends BaseDao<ChatMessage> {

    Optional<ChatMessage> findTopByConversationIdOrderByIdDesc(@Param("conversationId") Long conversationId);

    long countByConversationIdAndSenderIdNotAndIdGreaterThan(
            @Param("conversationId") Long conversationId,
            @Param("senderId") Long senderId,
            @Param("id") Long id);

    long countByConversationIdAndSenderIdNot(
            @Param("conversationId") Long conversationId,
            @Param("senderId") Long senderId);

    long countTemporaryMessagesByConversationId(@Param("conversationId") Long conversationId);
}
