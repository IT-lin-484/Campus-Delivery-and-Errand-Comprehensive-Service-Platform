package com.campusrunner.backend.conversation.dto;

import java.util.List;

import lombok.Data;

/**
 * 消息分页结果。
 */
@Data
public class MessageListResponse {
    private List<MessageItemResponse> list;
    private long total;
    private int page;
    private int pageSize;
    private Boolean friendConversation;
    private Boolean temporaryConversation;
    private Integer temporaryMessageLimit;
    private Integer temporaryMessageCount;
    private Integer temporaryMessageRemaining;
    private Boolean canSendMessage;
}
