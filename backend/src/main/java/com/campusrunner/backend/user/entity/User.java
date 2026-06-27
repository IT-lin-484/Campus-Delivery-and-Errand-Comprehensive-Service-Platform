package com.campusrunner.backend.user.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.campusrunner.backend.user.enums.UserRole;
import com.campusrunner.backend.user.enums.UserStatus;
import lombok.Data;

import java.time.LocalDateTime;


/**
 * 骞冲彴鐢ㄦ埛瀹炰綋銆? */

@Data
@TableName("users")
public class User {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;

    private String passwordHash;

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

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}

