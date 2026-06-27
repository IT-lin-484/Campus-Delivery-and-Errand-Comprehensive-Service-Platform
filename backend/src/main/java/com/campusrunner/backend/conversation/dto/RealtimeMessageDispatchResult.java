package com.campusrunner.backend.conversation.dto;

import java.util.Map;

/**
 * 实时消息发送结果。
 */
public record RealtimeMessageDispatchResult(
        MessageItemResponse senderAck,
        Map<Long, MessageItemResponse> recipientMessages) {
}
