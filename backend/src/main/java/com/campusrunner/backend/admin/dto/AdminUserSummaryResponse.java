package com.campusrunner.backend.admin.dto;

import lombok.Data;

import java.time.LocalDateTime;

import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * 绠＄悊鍛樼敤鎴峰垪琛ㄩ」銆?
 */
@Data
public class AdminUserSummaryResponse {
    private Long id;
    private String username;
    private String nickname;
    private String phone;
    private String avatarUrl;
    private UserRole role;
    private UserStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

}
