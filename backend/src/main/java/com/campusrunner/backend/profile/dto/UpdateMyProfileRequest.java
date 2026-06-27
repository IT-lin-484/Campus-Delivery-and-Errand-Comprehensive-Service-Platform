package com.campusrunner.backend.profile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Request payload for updating the current user's profile.
 */
@Data
public class UpdateMyProfileRequest {

    @NotBlank(message = "用户名不能为空")
    @Size(min = 4, max = 32, message = "用户名长度应为 4 到 32 位")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "用户名只能包含字母、数字和下划线")
    private String username;

    @NotBlank(message = "昵称不能为空")
    @Size(max = 64, message = "昵称长度不能超过 64 位")
    private String nickname;

    @Size(max = 20, message = "手机号长度不能超过 20 位")
    private String phone;

    @Size(max = 120, message = "常用地址长度不能超过 120 位")
    private String commonAddress;

    @Size(max = 200, message = "个人简介长度不能超过 200 位")
    private String bio;

    @NotNull(message = "allowFriendRequest 不能为空")
    private Boolean allowFriendRequest;

    @NotNull(message = "allowSearch 不能为空")
    private Boolean allowSearch;

    @NotNull(message = "messageDnd 不能为空")
    private Boolean messageDnd;
}
