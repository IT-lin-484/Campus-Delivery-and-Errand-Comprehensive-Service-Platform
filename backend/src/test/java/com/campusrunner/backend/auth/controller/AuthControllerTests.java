package com.campusrunner.backend.auth.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
 * 认证接口集成测试。
 */
@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void registerAndLoginShouldSuccess() throws Exception {
        Map<String, Object> registerBody = Map.of(
                "username", "runner1001",
                "password", "12345678",
                "nickname", "测试用户",
                "phone", "13812345678");

        String registerResponse = mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isString())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.user.username").value("runner1001"))
                .andExpect(jsonPath("$.user.role").value("USER"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        String token = objectMapper.readTree(registerResponse).get("token").asText();

        mockMvc.perform(get("/api/v1/auth/me")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("runner1001"))
                .andExpect(jsonPath("$.role").value("USER"));

        Map<String, Object> loginBody = Map.of(
                "username", "runner1001",
                "password", "12345678");

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isString())
                .andExpect(jsonPath("$.user.username").value("runner1001"));
    }

    @Test
    void registerDuplicateUsernameShouldFail() throws Exception {
        Map<String, Object> body = Map.of(
                "username", "runner1002",
                "password", "12345678");

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("用户名已存在"));
    }

    @Test
    void adminRegisterAndLoginShouldSuccess() throws Exception {
        Map<String, Object> registerBody = Map.of(
                "username", "admin1001",
                "password", "12345678",
                "nickname", "管理员甲",
                "phone", "13912345678",
                "inviteCode", "9527");

        String registerResponse = mockMvc.perform(post("/api/v1/auth/admin/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isString())
                .andExpect(jsonPath("$.user.username").value("admin1001"))
                .andExpect(jsonPath("$.user.role").value("ADMIN"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        String token = objectMapper.readTree(registerResponse).get("token").asText();

        mockMvc.perform(get("/api/v1/auth/me")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("admin1001"))
                .andExpect(jsonPath("$.role").value("ADMIN"));

        Map<String, Object> loginBody = Map.of(
                "username", "admin1001",
                "password", "12345678");

        mockMvc.perform(post("/api/v1/auth/admin/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isString())
                .andExpect(jsonPath("$.user.role").value("ADMIN"));
    }

    @Test
    void adminRegisterWithWrongInviteCodeShouldFail() throws Exception {
        Map<String, Object> registerBody = Map.of(
                "username", "admin1002",
                "password", "12345678",
                "nickname", "管理员乙",
                "phone", "13712345678",
                "inviteCode", "wrong-code");

        mockMvc.perform(post("/api/v1/auth/admin/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerBody)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("管理员邀请码错误"));
    }

    @Test
    void userShouldNotLoginFromAdminLoginApi() throws Exception {
        Map<String, Object> registerBody = Map.of(
                "username", "runner2001",
                "password", "12345678",
                "nickname", "普通用户",
                "phone", "13612345678");

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerBody)))
                .andExpect(status().isOk());

        Map<String, Object> loginBody = Map.of(
                "username", "runner2001",
                "password", "12345678");

        mockMvc.perform(post("/api/v1/auth/admin/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginBody)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("当前账号不是管理员"));
    }
}
