package com.campusrunner.backend.notification.service.impl;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campusrunner.backend.notification.dto.OrderCancelNotificationItemResponse;
import com.campusrunner.backend.notification.dto.UnreadNotificationSummaryResponse;
import com.campusrunner.backend.order.dao.OrderCancelRequestDao;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.order.entity.OrderCancelRequest;
import com.campusrunner.backend.order.enums.OrderCancelRequestStatus;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.social.dao.FriendRequestDao;
import com.campusrunner.backend.social.enums.FriendRequestStatus;
import com.campusrunner.backend.conversation.service.ConversationService;

/**
 * Unified unread notification service.
 */
@Service
public class NotificationServiceImpl implements com.campusrunner.backend.notification.service.NotificationService {

    private static final Set<OrderCancelRequestStatus> REQUESTER_RESULT_STATUSES = Set.of(
            OrderCancelRequestStatus.APPROVED,
            OrderCancelRequestStatus.REJECTED);
    private static final List<OrderStatus> ACTIVE_ORDER_STATUSES = List.of(
            OrderStatus.ACCEPTED,
            OrderStatus.IN_PROGRESS,
            OrderStatus.DELIVERED);

    private final ConversationService conversationService;
    private final OrderCancelRequestDao orderCancelRequestDao;
    private final OrderDao orderDao;
    private final FriendRequestDao friendRequestDao;

    public NotificationServiceImpl(
            ConversationService conversationService,
            OrderCancelRequestDao orderCancelRequestDao,
            OrderDao orderDao,
            FriendRequestDao friendRequestDao) {
        this.conversationService = conversationService;
        this.orderCancelRequestDao = orderCancelRequestDao;
        this.orderDao = orderDao;
        this.friendRequestDao = friendRequestDao;
    }

    @Override
    @Transactional(readOnly = true)
    public UnreadNotificationSummaryResponse getUnreadSummary(Long currentUserId) {
        long chatUnreadCount = conversationService.countTotalUnreadMessages(currentUserId);
        long orderCancelUnreadCount = countOrderCancelUnread(currentUserId);
        long requesterActiveOrderCount = orderDao.countByRequesterIdAndStatuses(currentUserId, ACTIVE_ORDER_STATUSES);
        long runnerActiveOrderCount = orderDao.countByRunnerIdAndStatuses(currentUserId, ACTIVE_ORDER_STATUSES);
        long friendRequestUnreadCount = friendRequestDao.countByToUserIdAndStatus(
                currentUserId,
                FriendRequestStatus.PENDING);
        long myOrderNoticeCount = requesterActiveOrderCount + runnerActiveOrderCount + orderCancelUnreadCount;
        long myPageNoticeCount = myOrderNoticeCount + friendRequestUnreadCount;

        UnreadNotificationSummaryResponse response = new UnreadNotificationSummaryResponse();
        response.setChatUnreadCount(chatUnreadCount);
        response.setOrderCancelUnreadCount(orderCancelUnreadCount);
        response.setTotalUnreadCount(chatUnreadCount + orderCancelUnreadCount);
        response.setRequesterActiveOrderCount(requesterActiveOrderCount);
        response.setRunnerActiveOrderCount(runnerActiveOrderCount);
        response.setFriendRequestUnreadCount(friendRequestUnreadCount);
        response.setMyOrderNoticeCount(myOrderNoticeCount);
        response.setMyPageNoticeCount(myPageNoticeCount);
        return response;
    }

    @Override
    @Transactional
    public UnreadNotificationSummaryResponse markOrderCancelNotificationsRead(Long currentUserId) {
        LocalDateTime now = LocalDateTime.now();
        orderCancelRequestDao.markRunnerUnreadAsRead(currentUserId, OrderCancelRequestStatus.PENDING, now);
        orderCancelRequestDao.markRequesterUnreadAsRead(currentUserId, REQUESTER_RESULT_STATUSES, now);
        return getUnreadSummary(currentUserId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<OrderCancelNotificationItemResponse> listOrderCancelNotifications(Long currentUserId, int limit) {
        List<OrderCancelNotificationItemResponse> merged = new ArrayList<>();

        List<OrderCancelRequest> runnerPendingRequests = orderCancelRequestDao
                .findTop20ByRunnerIdAndStatusOrderByCreatedAtDesc(currentUserId, OrderCancelRequestStatus.PENDING);
        for (OrderCancelRequest request : runnerPendingRequests) {
            merged.add(toRunnerPendingNotification(request));
        }

        List<OrderCancelRequest> requesterHandledRequests = orderCancelRequestDao
                .findTop20ByRequesterIdAndStatusInOrderByHandledAtDesc(currentUserId, REQUESTER_RESULT_STATUSES);
        for (OrderCancelRequest request : requesterHandledRequests) {
            merged.add(toRequesterResultNotification(request));
        }

        return merged.stream()
                .sorted(Comparator.comparing(
                        OrderCancelNotificationItemResponse::getEventTime,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(Math.max(1, Math.min(limit, 50)))
                .toList();
    }

    private long countOrderCancelUnread(Long currentUserId) {
        long runnerUnread = orderCancelRequestDao.countByRunnerIdAndStatusAndRunnerReadAtIsNull(
                currentUserId,
                OrderCancelRequestStatus.PENDING);
        long requesterUnread = orderCancelRequestDao.countByRequesterIdAndStatusInAndRequesterReadAtIsNull(
                currentUserId,
                REQUESTER_RESULT_STATUSES);
        return runnerUnread + requesterUnread;
    }

    private OrderCancelNotificationItemResponse toRunnerPendingNotification(OrderCancelRequest request) {
        OrderCancelNotificationItemResponse response = new OrderCancelNotificationItemResponse();
        response.setCancelRequestId(request.getId());
        response.setOrderId(request.getOrderId());
        response.setNotificationType("RUNNER_PENDING_REQUEST");
        response.setTitle("订单取消申请待处理");
        response.setContent("订单#" + request.getOrderId() + "：发单方申请取消，原因：" + request.getReason());
        response.setStatus(request.getStatus());
        response.setUnread(request.getRunnerReadAt() == null);
        response.setEventTime(request.getCreatedAt());
        return response;
    }

    private OrderCancelNotificationItemResponse toRequesterResultNotification(OrderCancelRequest request) {
        boolean approved = request.getStatus() == OrderCancelRequestStatus.APPROVED;
        String title = approved ? "取消申请已同意" : "取消申请已拒绝";

        StringBuilder contentBuilder = new StringBuilder();
        contentBuilder.append("订单#").append(request.getOrderId()).append("：接单方");
        contentBuilder.append(approved ? "同意了你的取消申请" : "拒绝了你的取消申请");
        if (request.getHandleNote() != null && !request.getHandleNote().isBlank()) {
            contentBuilder.append("，备注：").append(request.getHandleNote().trim());
        }

        OrderCancelNotificationItemResponse response = new OrderCancelNotificationItemResponse();
        response.setCancelRequestId(request.getId());
        response.setOrderId(request.getOrderId());
        response.setNotificationType("REQUESTER_HANDLE_RESULT");
        response.setTitle(title);
        response.setContent(contentBuilder.toString());
        response.setStatus(request.getStatus());
        response.setUnread(request.getRequesterReadAt() == null);
        response.setEventTime(request.getHandledAt() == null ? request.getUpdatedAt() : request.getHandledAt());
        return response;
    }
}
