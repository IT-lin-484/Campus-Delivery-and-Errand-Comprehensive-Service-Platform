package com.campusrunner.backend.notification.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import com.campusrunner.backend.notification.dto.OrderCancelNotificationItemResponse;
import com.campusrunner.backend.notification.dto.UnreadNotificationSummaryResponse;
import com.campusrunner.backend.order.entity.OrderCancelRequest;
import com.campusrunner.backend.order.enums.OrderCancelRequestStatus;
import com.campusrunner.backend.order.dao.OrderCancelRequestDao;

public interface NotificationService {
    UnreadNotificationSummaryResponse getUnreadSummary(Long currentUserId);
    UnreadNotificationSummaryResponse markOrderCancelNotificationsRead(Long currentUserId);
    List<OrderCancelNotificationItemResponse> listOrderCancelNotifications(Long currentUserId, int limit);
}

