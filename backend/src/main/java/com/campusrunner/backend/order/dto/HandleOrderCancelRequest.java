package com.campusrunner.backend.order.dto;

import lombok.Data;

import jakarta.validation.constraints.Size;

/**
 * 鎺ュ崟鏂瑰鐞嗗彇娑堢敵璇疯姹傘€?
 */
@Data
public class HandleOrderCancelRequest {

    @Size(max = 200, message = "澶勭悊澶囨敞闀垮害涓嶈兘瓒呰繃200")
    private String note;

}
