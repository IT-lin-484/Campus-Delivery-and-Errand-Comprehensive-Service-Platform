package com.campusrunner.backend.notification.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDateTime;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 未读通知接口集成测试。
 */
@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class NotificationControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void unreadSummaryShouldIncludeChatAndCancelUnread() throws Exception {
        long requesterId = registerUser("nr" + System.nanoTime());
        long runnerId = registerUser("nu" + System.nanoTime());

        long orderId = createOrder(requesterId, "通知统计测试");
        acceptAndGoInProgress(orderId, runnerId);
        requesterApplyCancel(orderId, requesterId, "临时不需要了");

        long conversationId = createOrGetConversation(requesterId, runnerId);
        sendConversationMessage(requesterId, conversationId, "这是给接单方的未读消息");

        mockMvc.perform(get("/api/v1/notifications/unread-summary")
                .header("X-User-Id", String.valueOf(runnerId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.chatUnreadCount").value(1))
                .andExpect(jsonPath("$.orderCancelUnreadCount").value(1))
                .andExpect(jsonPath("$.totalUnreadCount").value(2));
    }

    @Test
    void runnerReadAllShouldClearPendingCancelUnread() throws Exception {
        long requesterId = registerUser("n2r" + System.nanoTime());
        long runnerId = registerUser("n2u" + System.nanoTime());

        long orderId = createOrder(requesterId, "接单方通知已读");
        acceptAndGoInProgress(orderId, runnerId);
        requesterApplyCancel(orderId, requesterId, "申请取消");

        mockMvc.perform(post("/api/v1/notifications/order-cancel/read-all")
                .header("X-User-Id", String.valueOf(runnerId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderCancelUnreadCount").value(0));
    }

    @Test
    void requesterShouldReceiveUnreadAfterRunnerHandlesCancel() throws Exception {
        long requesterId = registerUser("n3r" + System.nanoTime());
        long runnerId = registerUser("n3u" + System.nanoTime());

        long orderId = createOrder(requesterId, "需求方处理结果未读");
        acceptAndGoInProgress(orderId, runnerId);
        requesterApplyCancel(orderId, requesterId, "申请取消");

        mockMvc.perform(post("/api/v1/orders/{id}/cancel/reject", orderId)
                .header("X-User-Id", String.valueOf(runnerId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("note", "不同意"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"));

        mockMvc.perform(get("/api/v1/notifications/unread-summary")
                .header("X-User-Id", String.valueOf(requesterId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderCancelUnreadCount").value(1));

        mockMvc.perform(post("/api/v1/notifications/order-cancel/read-all")
                .header("X-User-Id", String.valueOf(requesterId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderCancelUnreadCount").value(0));
    }

    private long createOrder(long requesterId, String remark) throws Exception {
        Map<String, Object> createBody = Map.of(
                "type", "EXPRESS",
                "pickupLocation", "北门驿站",
                "dropoffLocation", "2号宿舍楼下",
                "expectedTime", LocalDateTime.now().plusHours(2).withNano(0).toString(),
                "rewardAmount", 10,
                "contactMode", "IN_APP",
                "remark", remark);

        String createResponse = mockMvc.perform(post("/api/v1/orders")
                .header("X-User-Id", String.valueOf(requesterId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createBody)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(createResponse).get("id").asLong();
    }

    private void acceptAndGoInProgress(long orderId, long runnerId) throws Exception {
        mockMvc.perform(post("/api/v1/orders/{id}/accept", orderId)
                .header("X-User-Id", String.valueOf(runnerId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACCEPTED"));

        Map<String, Object> inProgressBody = Map.of(
                "toStatus", "IN_PROGRESS",
                "note", "开始执行");
        mockMvc.perform(post("/api/v1/orders/{id}/status", orderId)
                .header("X-User-Id", String.valueOf(runnerId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(inProgressBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"));
    }

    private void requesterApplyCancel(long orderId, long requesterId, String reason) throws Exception {
        mockMvc.perform(post("/api/v1/orders/{id}/cancel", orderId)
                .header("X-User-Id", String.valueOf(requesterId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("reason", reason))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"))
                .andExpect(jsonPath("$.cancelRequest.status").value("PENDING"));
    }

    private long createOrGetConversation(long userId, long targetUserId) throws Exception {
        String response = mockMvc.perform(post("/api/v1/conversations")
                .header("X-User-Id", String.valueOf(userId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("friendUserId", targetUserId))))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(response).get("id").asLong();
    }

    private void sendConversationMessage(long userId, long conversationId, String content) throws Exception {
        mockMvc.perform(post("/api/v1/conversations/{id}/messages", conversationId)
                .header("X-User-Id", String.valueOf(userId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("content", content))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.conversationId").value(conversationId));
    }

    private long registerUser(String username) throws Exception {
        Map<String, Object> body = Map.of(
                "username", username,
                "password", "12345678",
                "nickname", username,
                "phone", "13800000000");

        String response = mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(response).path("user").path("id").asLong();
    }
}
