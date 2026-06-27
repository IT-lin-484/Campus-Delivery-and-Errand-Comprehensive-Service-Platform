package com.campusrunner.backend.websocket;

/**
 * WebSocket 客户端命令。
 */
public record SocketCommand(
        String type,
        Long conversationId,
        String clientMessageId,
        String content) {
}
