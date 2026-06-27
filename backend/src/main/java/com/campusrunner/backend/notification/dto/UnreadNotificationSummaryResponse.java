package com.campusrunner.backend.notification.dto;

import lombok.Data;

/**
 * 椤堕儴娑堟伅鍏ュ彛鏈缁熻銆?
 */
@Data
public class UnreadNotificationSummaryResponse {
    private Long totalUnreadCount;
    private Long chatUnreadCount;
    private Long orderCancelUnreadCount;
    private Long requesterActiveOrderCount;
    private Long runnerActiveOrderCount;
    private Long friendRequestUnreadCount;
    private Long myOrderNoticeCount;
    private Long myPageNoticeCount;
}
