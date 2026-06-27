package com.campusrunner.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * User registration request.
 */
@Data
public class RegisterRequest {

    @NotBlank(message = "must not be blank")
    @Size(min = 4, max = 32, message = "用户名长度应为 4 到 32")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "用户名只能包含字母、数字和下划线")
    private String username;

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 32, message = "密码长度应为 6 到 32")
    private String password;

    @Size(max = 64, message = "昵称长度不能超过 64")
    private String nickname;

    @Size(max = 20, message = "手机号长度不能超过 20")
    private String phone;
}
