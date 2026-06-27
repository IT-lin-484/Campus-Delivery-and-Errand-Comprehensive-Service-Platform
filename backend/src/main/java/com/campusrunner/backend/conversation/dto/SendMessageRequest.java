package com.campusrunner.backend.conversation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 发送文本消息请求。
 */
@Data
public class SendMessageRequest {

    @Size(max = 64, message = "客户端消息ID长度不能超过64")
    private String clientMessageId;

    @NotBlank(message = "消息内容不能为空")
    @Size(max = 1000, message = "消息内容不能超过1000")
    private String content;
}
