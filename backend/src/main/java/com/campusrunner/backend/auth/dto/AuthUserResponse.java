package com.campusrunner.backend.auth.dto;

import lombok.Data;

import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * 鐧诲綍鎬佷腑鐨勭敤鎴蜂俊鎭€?
 */
@Data
public class AuthUserResponse {
    private Long id;
    private String username;
    private String nickname;
    private String phone;
    private String avatarUrl;
    private String commonAddress;
    private String bio;
    private Boolean allowFriendRequest;
    private Boolean allowSearch;
    private Boolean messageDnd;
    private UserRole role;
    private UserStatus status;

}
