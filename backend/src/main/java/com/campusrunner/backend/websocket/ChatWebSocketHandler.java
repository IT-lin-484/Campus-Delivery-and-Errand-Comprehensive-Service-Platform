package com.campusrunner.backend.websocket;

import java.io.IOException;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.campusrunner.backend.conversation.dto.RealtimeMessageDispatchResult;
import com.campusrunner.backend.conversation.dto.SendMessageRequest;
import com.campusrunner.backend.conversation.service.ConversationService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * 聊天 WebSocket 处理器。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private final ObjectMapper objectMapper;
    private final ChatSessionRegistry sessionRegistry;
    private final ConversationService conversationService;
    private final PresenceService presenceService;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = requireUserId(session);
        presenceService.handleConnected(userId, session);
        send(session, SocketEvent.connected(userId, presenceService.getHeartbeatIntervalSeconds()));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        Long userId = requireUserId(session);
        presenceService.refreshHeartbeat(session);

        SocketCommand command = objectMapper.readValue(message.getPayload(), SocketCommand.class);
        if ("PING".equalsIgnoreCase(command.type())) {
            send(session, SocketEvent.pong());
            return;
        }

        if (!"CHAT_SEND".equalsIgnoreCase(command.type())) {
            send(session, SocketEvent.error(command.conversationId(), 40040, "未知的 WebSocket 指令"));
            return;
        }

        if (command.conversationId() == null) {
            send(session, SocketEvent.error(null, 40041, "conversationId 不能为空"));
            return;
        }
        if (command.content() == null || command.content().isBlank()) {
            send(session, SocketEvent.error(command.conversationId(), 40042, "消息内容不能为空"));
            return;
        }

        try {
            SendMessageRequest sendMessageRequest = new SendMessageRequest();
            sendMessageRequest.setClientMessageId(command.clientMessageId());
            sendMessageRequest.setContent(command.content());
            RealtimeMessageDispatchResult dispatch = conversationService.sendTextMessageByRealtime(
                    userId,
                    command.conversationId(),
                    sendMessageRequest);

            send(session, SocketEvent.ack(command.conversationId(), dispatch.senderAck()));
            for (var entry : dispatch.recipientMessages().entrySet()) {
                sessionRegistry.sendToUser(
                        entry.getKey(),
                        write(SocketEvent.received(command.conversationId(), entry.getValue())));
            }
        } catch (RuntimeException ex) {
            send(session, SocketEvent.error(command.conversationId(), 50000, ex.getMessage() == null ? "发送失败" : ex.getMessage()));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        try {
            Long userId = requireUserId(session);
            presenceService.handleDisconnected(userId, session);
        } catch (IllegalStateException ignored) {
            // 未鉴权会话直接忽略。
        }
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        log.warn("WebSocket transport error: {}", exception.getMessage());
        if (session.isOpen()) {
            session.close(CloseStatus.SERVER_ERROR);
        }
    }

    private void send(WebSocketSession session, SocketEvent event) throws IOException {
        synchronized (session) {
            session.sendMessage(new TextMessage(write(event)));
        }
    }

    private String write(SocketEvent event) throws JsonProcessingException {
        return objectMapper.writeValueAsString(event);
    }

    private Long requireUserId(WebSocketSession session) {
        Object userId = session.getAttributes().get("userId");
        if (userId instanceof Long value) {
            return value;
        }
        if (userId instanceof Integer value) {
            return value.longValue();
        }
        throw new IllegalStateException("Missing userId in websocket session");
    }
}
