package com.campusrunner.backend.conversation.dto;

import lombok.Data;

/**
 * Request payload for creating or opening a private conversation.
 */
@Data
public class CreatePrivateConversationRequest {

    private Long friendId;

    private Long friendUserId;

    private Long orderId;

    public Long resolveTargetUserId() {
        return friendId != null ? friendId : friendUserId;
    }
}
