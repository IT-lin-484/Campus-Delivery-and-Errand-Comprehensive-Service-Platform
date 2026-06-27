package com.campusrunner.backend.websocket;

import java.util.Map;

/**
 * WebSocket 服务端事件。
 */
public record SocketEvent(
        String type,
        Long conversationId,
        Object data,
        Integer code,
        String message) {

    public static SocketEvent connected(Long userId, int heartbeatIntervalSeconds) {
        return new SocketEvent(
                "CONNECTED",
                null,
                Map.of(
                        "userId", userId,
                        "heartbeatIntervalSeconds", heartbeatIntervalSeconds),
                null,
                "连接成功");
    }

    public static SocketEvent pong() {
        return new SocketEvent("PONG", null, null, null, "pong");
    }

    public static SocketEvent ack(Long conversationId, Object data) {
        return new SocketEvent("MESSAGE_ACK", conversationId, data, null, "消息已送达");
    }

    public static SocketEvent received(Long conversationId, Object data) {
        return new SocketEvent("MESSAGE_RECEIVED", conversationId, data, null, "收到新消息");
    }

    public static SocketEvent presenceChanged(Long userId, boolean online) {
        return new SocketEvent(
                "PRESENCE_CHANGED",
                null,
                Map.of("userId", userId, "online", online),
                null,
                online ? "用户上线" : "用户离线");
    }

    public static SocketEvent error(Long conversationId, int code, String message) {
        return new SocketEvent("ERROR", conversationId, null, code, message);
    }
}
