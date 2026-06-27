package com.campusrunner.backend.order.dto;

import lombok.Data;

import jakarta.validation.constraints.Size;

/**
 * 鍙栨秷璁㈠崟璇锋眰銆?
 */
@Data
public class CancelOrderRequest {

    @Size(max = 200, message = "鍙栨秷鍘熷洜闀垮害涓嶈兘瓒呰繃200")
    private String reason;

}
