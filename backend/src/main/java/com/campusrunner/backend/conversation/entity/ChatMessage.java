package com.campusrunner.backend.conversation.entity;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campusrunner.backend.conversation.enums.MessageContentType;
import com.campusrunner.backend.conversation.enums.MessageStatus;

import lombok.Data;

/**
 * 会话消息实体。
 */
@Data
@TableName("messages")
public class ChatMessage {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long conversationId;

    private Long senderId;

    private String clientMessageId;

    private MessageContentType contentType;

    private String content;

    private MessageStatus status;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime sentAt;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
