package com.campusrunner.backend.websocket;

import java.io.IOException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

/**
 * WebSocket 会话注册表。
 */
@Component
public class ChatSessionRegistry {

    private final ConcurrentHashMap<String, TrackedSession> sessionsById = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, Set<String>> sessionIdsByUserId = new ConcurrentHashMap<>();

    public boolean register(Long userId, WebSocketSession session) {
        boolean wasOnline = isUserOnline(userId);
        sessionsById.put(
                session.getId(),
                new TrackedSession(userId, session, new AtomicLong(System.currentTimeMillis())));
        sessionIdsByUserId.computeIfAbsent(userId, key -> ConcurrentHashMap.newKeySet()).add(session.getId());
        return !wasOnline;
    }

    public boolean unregister(Long userId, WebSocketSession session) {
        TrackedSession removed = sessionsById.remove(session.getId());
        if (removed == null) {
            return false;
        }

        Long actualUserId = removed.userId();
        Set<String> sessionIds = sessionIdsByUserId.get(actualUserId);
        if (sessionIds != null) {
            sessionIds.remove(session.getId());
            if (sessionIds.isEmpty()) {
                sessionIdsByUserId.remove(actualUserId);
            }
        }
        return !isUserOnline(actualUserId);
    }

    public void touch(WebSocketSession session) {
        TrackedSession trackedSession = sessionsById.get(session.getId());
        if (trackedSession == null) {
            return;
        }
        trackedSession.lastSeenAt().set(System.currentTimeMillis());
    }

    public boolean isUserOnline(Long userId) {
        Set<String> sessionIds = sessionIdsByUserId.get(userId);
        return sessionIds != null && !sessionIds.isEmpty();
    }

    public List<Long> closeExpiredSessions(Duration maxIdle) {
        long cutoff = System.currentTimeMillis() - maxIdle.toMillis();
        Set<Long> offlineUsers = new LinkedHashSet<>();

        for (TrackedSession trackedSession : new ArrayList<>(sessionsById.values())) {
            if (trackedSession.lastSeenAt().get() >= cutoff) {
                continue;
            }

            closeQuietly(trackedSession.session());
            if (unregister(trackedSession.userId(), trackedSession.session())) {
                offlineUsers.add(trackedSession.userId());
            }
        }

        return List.copyOf(offlineUsers);
    }

    public void sendToUser(Long userId, String payload) throws IOException {
        Set<String> sessionIds = sessionIdsByUserId.get(userId);
        if (sessionIds == null || sessionIds.isEmpty()) {
            return;
        }

        for (String sessionId : Set.copyOf(sessionIds)) {
            TrackedSession trackedSession = sessionsById.get(sessionId);
            if (trackedSession == null) {
                continue;
            }

            WebSocketSession session = trackedSession.session();
            if (!session.isOpen()) {
                unregister(userId, session);
                continue;
            }

            synchronized (session) {
                session.sendMessage(new TextMessage(payload));
            }
        }
    }

    private void closeQuietly(WebSocketSession session) {
        try {
            if (session.isOpen()) {
                session.close(CloseStatus.SESSION_NOT_RELIABLE);
            }
        } catch (IOException ignored) {
            // 关闭失败不影响后续清理。
        }
    }

    private record TrackedSession(
            Long userId,
            WebSocketSession session,
            AtomicLong lastSeenAt) {
    }
}
