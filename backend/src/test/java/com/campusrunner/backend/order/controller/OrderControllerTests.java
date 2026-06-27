package com.campusrunner.backend.order.controller;

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
 * 订单接口集成测试。
 */
@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void createOrderShouldSuccess() throws Exception {
        Map<String, Object> body = Map.of(
                "type", "EXPRESS",
                "pickupLocation", "菜鸟驿站（北门）",
                "dropoffLocation", "1号宿舍楼下",
                "expectedTime", LocalDateTime.now().plusHours(2).withNano(0).toString(),
                "rewardAmount", 8,
                "contactMode", "IN_APP",
                "remark", "取件码1234");

        mockMvc.perform(post("/api/v1/orders")
                .header("X-User-Id", "20001")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.requesterId").value(20001))
                .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void listAndDetailShouldSuccess() throws Exception {
        Map<String, Object> body = Map.of(
                "type", "FOOD",
                "pickupLocation", "校门口",
                "dropoffLocation", "教学楼A-3楼",
                "expectedTime", LocalDateTime.now().plusHours(1).withNano(0).toString(),
                "rewardAmount", 6,
                "contactMode", "IN_APP",
                "remark", "尽快送达");

        String createResponse = mockMvc.perform(post("/api/v1/orders")
                .header("X-User-Id", "20002")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Long orderId = objectMapper.readTree(createResponse).get("id").asLong();

        mockMvc.perform(get("/api/v1/orders")
                .param("status", "OPEN")
                .param("page", "1")
                .param("page_size", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1))
                .andExpect(jsonPath("$.list[0].id").value(orderId))
                .andExpect(jsonPath("$.list[0].type").value("FOOD"));

        mockMvc.perform(get("/api/v1/orders/{id}", orderId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(orderId))
                .andExpect(jsonPath("$.pickupLocation").value("校门口"))
                .andExpect(jsonPath("$.dropoffLocation").value("教学楼A-3楼"))
                .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void fullStatusFlowShouldSuccess() throws Exception {
        long requesterId = registerUser("flow_requester_" + System.nanoTime());
        long runnerId = registerUser("flow_runner_" + System.nanoTime());

        Map<String, Object> createBody = Map.of(
                "type", "EXPRESS",
                "pickupLocation", "北门驿站",
                "dropoffLocation", "2号宿舍楼下",
                "expectedTime", LocalDateTime.now().plusHours(2).withNano(0).toString(),
                "rewardAmount", 10,
                "contactMode", "IN_APP",
                "remark", "测试状态流转");

        String createResponse = mockMvc.perform(post("/api/v1/orders")
                .header("X-User-Id", String.valueOf(requesterId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createBody)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        Long orderId = objectMapper.readTree(createResponse).get("id").asLong();

        mockMvc.perform(post("/api/v1/orders/{id}/accept", orderId)
                .header("X-User-Id", String.valueOf(runnerId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACCEPTED"))
                .andExpect(jsonPath("$.runnerId").value(runnerId));

        Map<String, Object> inProgressBody = Map.of(
                "toStatus", "IN_PROGRESS",
                "note", "开始执行");
        mockMvc.perform(post("/api/v1/orders/{id}/status", orderId)
                .header("X-User-Id", String.valueOf(runnerId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(inProgressBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"));

        Map<String, Object> deliveredBody = Map.of(
                "toStatus", "DELIVERED",
                "note", "已送达");
        mockMvc.perform(post("/api/v1/orders/{id}/status", orderId)
                .header("X-User-Id", String.valueOf(runnerId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(deliveredBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DELIVERED"));

        mockMvc.perform(post("/api/v1/orders/{id}/confirm", orderId)
                .header("X-User-Id", String.valueOf(requesterId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));
    }

    @Test
    void requesterCannotCancelAfterDelivered() throws Exception {
        long requesterId = registerUser("cadr_" + System.nanoTime());
        long runnerId = registerUser("cadu_" + System.nanoTime());

        long orderId = createOrder(requesterId, "已送达不可取消");
        acceptAndGoInProgress(orderId, runnerId);

        Map<String, Object> deliveredBody = Map.of(
                "toStatus", "DELIVERED",
                "note", "已送达");
        mockMvc.perform(post("/api/v1/orders/{id}/status", orderId)
                .header("X-User-Id", String.valueOf(runnerId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(deliveredBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DELIVERED"));

        mockMvc.perform(post("/api/v1/orders/{id}/cancel", orderId)
                .header("X-User-Id", String.valueOf(requesterId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("reason", "想取消"))))
                .andExpect(status().isBadRequest());
    }

    @Test
    void requesterCancelInProgressNeedsApprovalAndHasDailyQuota() throws Exception {
        long requesterId = registerUser("cqr_" + System.nanoTime());
        long runnerId = registerUser("cqu1_" + System.nanoTime());
        long runner2Id = registerUser("cqu2_" + System.nanoTime());

        long orderId1 = createOrder(requesterId, "进行中取消申请-1");
        acceptAndGoInProgress(orderId1, runnerId);

        mockMvc.perform(post("/api/v1/orders/{id}/cancel", orderId1)
                .header("X-User-Id", String.valueOf(requesterId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("reason", "临时不需要了"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"))
                .andExpect(jsonPath("$.cancelRequest.status").value("PENDING"));

        mockMvc.perform(post("/api/v1/orders/{id}/cancel/approve", orderId1)
                .header("X-User-Id", String.valueOf(runnerId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("note", "同意取消"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"))
                .andExpect(jsonPath("$.cancelledBy").value("REQUESTER"));

        long orderId2 = createOrder(requesterId, "进行中取消申请-2");
        acceptAndGoInProgress(orderId2, runner2Id);

        mockMvc.perform(post("/api/v1/orders/{id}/cancel", orderId2)
                .header("X-User-Id", String.valueOf(requesterId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("reason", "再次取消"))))
                .andExpect(status().isTooManyRequests());
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
