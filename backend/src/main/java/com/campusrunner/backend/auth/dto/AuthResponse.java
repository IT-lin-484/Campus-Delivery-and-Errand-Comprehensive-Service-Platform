package com.campusrunner.backend.auth.dto;

import lombok.Data;

/**
 * 鐧诲綍鎴栨敞鍐屾垚鍔熷悗鐨勭粺涓€鍝嶅簲銆?
 */
@Data
public class AuthResponse {
    private String token;
    private String tokenType;
    private long expiresIn;
    private AuthUserResponse user;

}
