package com.campusrunner.backend.social.dto;

import lombok.Data;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 鍙戣捣濂藉弸鐢宠璇锋眰銆?
 */
@Data
public class SendFriendRequestRequest {

    @NotNull(message = "toUserId 涓嶈兘涓虹┖")
    private Long toUserId;

    @Size(max = 200, message = "楠岃瘉娑堟伅闀垮害涓嶈兘瓒呰繃200")
    private String message;

}
