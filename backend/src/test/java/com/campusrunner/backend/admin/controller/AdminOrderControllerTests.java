package com.campusrunner.backend.admin.controller;

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

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 管理员订单管理接口集成测试。
 */
@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminOrderControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void adminShouldListAndForceCancelOrder() throws Exception {
        String adminToken = registerAdminAndGetToken("admin_order_1", "13811112222");
        Long orderId = createOrder("30001", "菜鸟驿站", "2号宿舍楼下");

        mockMvc.perform(get("/api/v1/admin/orders")
                .header("Authorization", "Bearer " + adminToken)
                .param("status", "OPEN")
                .param("page", "1")
                .param("page_size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1))
                .andExpect(jsonPath("$.list[0].id").value(orderId));

        Map<String, Object> forceCancelBody = Map.of("reason", "发现违规信息，管理员强制取消");
        mockMvc.perform(post("/api/v1/admin/orders/{id}/force-cancel", orderId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(forceCancelBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"))
                .andExpect(jsonPath("$.cancelledBy").value("ADMIN"))
                .andExpect(jsonPath("$.cancelReason").value("发现违规信息，管理员强制取消"));
    }

    @Test
    void adminShouldMarkExceptionAndForceCompleteOrder() throws Exception {
        String adminToken = registerAdminAndGetToken("admin_order_2", "13811113333");
        Long orderId = createOrder("30002", "校门口", "教学楼A3楼");

        Map<String, Object> markBody = Map.of("note", "订单沟通异常，先标记复核");
        mockMvc.perform(post("/api/v1/admin/orders/{id}/mark-exception", orderId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(markBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.abnormalFlag").value(true))
                .andExpect(jsonPath("$.abnormalNote").value("订单沟通异常，先标记复核"));

        Map<String, Object> completeBody = Map.of("note", "管理员确认已处理完成");
        mockMvc.perform(post("/api/v1/admin/orders/{id}/force-complete", orderId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(completeBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.statusLogs").isArray());
    }

    @Test
    void normalUserShouldNotAccessAdminOrderApi() throws Exception {
        String userToken = registerUserAndGetToken("normal_user_1", "13811114444");

        mockMvc.perform(get("/api/v1/admin/orders")
                .header("Authorization", "Bearer " + userToken)
                .param("page", "1")
                .param("page_size", "10"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("当前账号无管理员权限"));
    }

    private String registerAdminAndGetToken(String username, String phone) throws Exception {
        Map<String, Object> body = Map.of(
                "username", username,
                "password", "12345678",
                "nickname", "管理员测试",
                "phone", phone,
                "inviteCode", "9527");
        String responseText = mockMvc.perform(post("/api/v1/auth/admin/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role").value("ADMIN"))
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode response = objectMapper.readTree(responseText);
        return response.get("token").asText();
    }

    private String registerUserAndGetToken(String username, String phone) throws Exception {
        Map<String, Object> body = Map.of(
                "username", username,
                "password", "12345678",
                "nickname", "普通用户测试",
                "phone", phone);
        String responseText = mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role").value("USER"))
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode response = objectMapper.readTree(responseText);
        return response.get("token").asText();
    }

    private Long createOrder(String requesterId, String pickupLocation, String dropoffLocation) throws Exception {
        Map<String, Object> body = Map.of(
                "type", "EXPRESS",
                "pickupLocation", pickupLocation,
                "dropoffLocation", dropoffLocation,
                "expectedTime", LocalDateTime.now().plusHours(2).withNano(0).toString(),
                "rewardAmount", 8,
                "contactMode", "IN_APP",
                "remark", "管理员订单管理测试");

        String responseText = mockMvc.perform(post("/api/v1/orders")
                .header("X-User-Id", requesterId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode response = objectMapper.readTree(responseText);
        return response.get("id").asLong();
    }
}
