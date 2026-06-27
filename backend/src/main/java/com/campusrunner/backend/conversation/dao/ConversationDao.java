package com.campusrunner.backend.conversation.dao;

import java.util.Optional;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.conversation.entity.Conversation;

/**
 * 会话 DAO。
 */
public interface ConversationDao extends BaseDao<Conversation> {

    Optional<Conversation> findByUserAIdAndUserBId(
            @Param("userAId") Long userAId,
            @Param("userBId") Long userBId);
}
