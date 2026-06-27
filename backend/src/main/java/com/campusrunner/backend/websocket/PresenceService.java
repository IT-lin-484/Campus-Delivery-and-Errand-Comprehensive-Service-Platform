package com.campusrunner.backend.websocket;

import java.io.IOException;
import java.time.Duration;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.WebSocketSession;

import com.campusrunner.backend.social.dao.FriendshipDao;
import com.campusrunner.backend.social.enums.FriendshipStatus;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * 在线状态服务。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PresenceService {

    private static final Duration HEARTBEAT_TIMEOUT = Duration.ofSeconds(70);
    private static final int HEARTBEAT_INTERVAL_SECONDS = 25;

    private final ChatSessionRegistry sessionRegistry;
    private final FriendshipDao friendshipDao;
    private final ObjectMapper objectMapper;

    public void handleConnected(Long userId, WebSocketSession session) {
        boolean becameOnline = sessionRegistry.register(userId, session);
        if (becameOnline) {
            notifyFriends(userId, true);
        }
    }

    public void handleDisconnected(Long userId, WebSocketSession session) {
        boolean becameOffline = sessionRegistry.unregister(userId, session);
        if (becameOffline) {
            notifyFriends(userId, false);
        }
    }

    public void refreshHeartbeat(WebSocketSession session) {
        sessionRegistry.touch(session);
    }

    public boolean isUserOnline(Long userId) {
        return sessionRegistry.isUserOnline(userId);
    }

    public int getHeartbeatIntervalSeconds() {
        return HEARTBEAT_INTERVAL_SECONDS;
    }

    @Scheduled(fixedDelay = 15000)
    public void evictStaleSessions() {
        for (Long offlineUserId : sessionRegistry.closeExpiredSessions(HEARTBEAT_TIMEOUT)) {
            notifyFriends(offlineUserId, false);
        }
    }

    private void notifyFriends(Long userId, boolean online) {
        List<Long> friendIds = friendshipDao.findByUserIdAndStatusOrderByUpdatedAtDesc(
                userId,
                FriendshipStatus.ACTIVE).stream()
                .map(friendship -> friendship.getFriendUserId())
                .toList();
        if (friendIds.isEmpty()) {
            return;
        }

        String payload;
        try {
            payload = objectMapper.writeValueAsString(SocketEvent.presenceChanged(userId, online));
        } catch (JsonProcessingException ex) {
            log.warn("Failed to serialize presence event for user {}", userId, ex);
            return;
        }

        for (Long friendId : friendIds) {
            try {
                sessionRegistry.sendToUser(friendId, payload);
            } catch (IOException ex) {
                log.warn("Failed to push presence update from {} to {}", userId, friendId, ex);
            }
        }
    }
}
