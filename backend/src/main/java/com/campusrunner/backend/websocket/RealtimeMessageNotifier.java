package com.campusrunner.backend.websocket;

import java.io.IOException;
import java.util.Map;

import org.springframework.stereotype.Component;

import com.campusrunner.backend.conversation.dto.MessageItemResponse;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * 负责把实时消息推送给在线接收者。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RealtimeMessageNotifier {

    private final ObjectMapper objectMapper;
    private final ChatSessionRegistry sessionRegistry;

    public void notifyRecipients(Long conversationId, Map<Long, MessageItemResponse> recipientMessages) {
        for (var entry : recipientMessages.entrySet()) {
            try {
                String payload = objectMapper.writeValueAsString(
                        SocketEvent.received(conversationId, entry.getValue()));
                sessionRegistry.sendToUser(entry.getKey(), payload);
            } catch (JsonProcessingException ex) {
                log.warn("Failed to serialize realtime message for conversation {}", conversationId, ex);
            } catch (IOException ex) {
                log.warn(
                        "Failed to push realtime message to user {} in conversation {}",
                        entry.getKey(),
                        conversationId,
                        ex);
            }
        }
    }
}
