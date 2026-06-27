package com.campusrunner.backend.order.service.impl;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.conversation.service.ConversationService;
import com.campusrunner.backend.order.dao.OrderCancelRequestDao;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.order.dao.OrderDeliveryImageDao;
import com.campusrunner.backend.order.dao.OrderStatusLogDao;
import com.campusrunner.backend.order.dto.CancelOrderRequest;
import com.campusrunner.backend.order.dto.CreateOrderRequest;
import com.campusrunner.backend.order.dto.HandleOrderCancelRequest;
import com.campusrunner.backend.order.dto.OrderCancelRequestResponse;
import com.campusrunner.backend.order.dto.OrderDeliveryImageResponse;
import com.campusrunner.backend.order.dto.OrderDetailResponse;
import com.campusrunner.backend.order.dto.OrderListResponse;
import com.campusrunner.backend.order.dto.OrderSummaryResponse;
import com.campusrunner.backend.order.dto.UpdateOrderRequest;
import com.campusrunner.backend.order.dto.UpdateOrderStatusRequest;
import com.campusrunner.backend.order.entity.Order;
import com.campusrunner.backend.order.entity.OrderCancelRequest;
import com.campusrunner.backend.order.entity.OrderDeliveryImage;
import com.campusrunner.backend.order.entity.OrderStatusLog;
import com.campusrunner.backend.order.enums.CancelledBy;
import com.campusrunner.backend.order.enums.ContactMode;
import com.campusrunner.backend.order.enums.OrderCancelRequestStatus;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;

/**
 * 订单服务实现。
 */
@Service
public class OrderServiceImpl implements com.campusrunner.backend.order.service.OrderService {

    private final OrderDao orderDao;
    private final OrderStatusLogDao orderStatusLogDao;
    private final OrderCancelRequestDao orderCancelRequestDao;
    private final OrderDeliveryImageDao orderDeliveryImageDao;
    private final ConversationService conversationService;
    private final UserDao userDao;

    public OrderServiceImpl(
            OrderDao orderDao,
            OrderStatusLogDao orderStatusLogDao,
            OrderCancelRequestDao orderCancelRequestDao,
            OrderDeliveryImageDao orderDeliveryImageDao,
            ConversationService conversationService,
            UserDao userDao) {
        this.orderDao = orderDao;
        this.orderStatusLogDao = orderStatusLogDao;
        this.orderCancelRequestDao = orderCancelRequestDao;
        this.orderDeliveryImageDao = orderDeliveryImageDao;
        this.conversationService = conversationService;
        this.userDao = userDao;
    }

    @Override
    @Transactional
    public OrderDetailResponse createOrder(Long requesterId, CreateOrderRequest request) {
        validateCreateOrUpdateRequest(
                request.getExpectedTime(),
                request.getContactMode(),
                request.getContactValue());

        Order order = new Order();
        order.setRequesterId(requesterId);
        order.setType(request.getType());
        order.setPickupLocation(request.getPickupLocation().trim());
        order.setDropoffLocation(request.getDropoffLocation().trim());
        order.setExpectedTime(request.getExpectedTime());
        order.setRewardAmount(request.getRewardAmount());
        order.setContactMode(request.getContactMode());
        order.setContactValue(normalizeContactValue(request.getContactMode(), request.getContactValue()));
        order.setRemark(normalizeText(request.getRemark()));
        order.setStatus(OrderStatus.OPEN);
        order.setAbnormalFlag(false);
        order.setAbnormalNote(null);

        return toDetailResponse(orderDao.save(order));
    }

    @Override
    @Transactional(readOnly = true)
    public OrderListResponse listOrders(OrderStatus status, OrderType type, String keyword, int page, int pageSize) {
        Page<Order> result = orderDao.selectPage(
                new Page<>(page, pageSize),
                buildQueryWrapper(status, type, keyword, null, null));
        return buildListResponse(result, page, pageSize);
    }

    @Override
    @Transactional(readOnly = true)
    public OrderListResponse listMyOrders(
            Long userId,
            String as,
            OrderStatus status,
            OrderType type,
            String keyword,
            int page,
            int pageSize) {
        if (!"requester".equalsIgnoreCase(as) && !"runner".equalsIgnoreCase(as)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "as 参数只能是 requester 或 runner");
        }

        Long requesterId = "requester".equalsIgnoreCase(as) ? userId : null;
        Long runnerId = "runner".equalsIgnoreCase(as) ? userId : null;
        Page<Order> result = orderDao.selectPage(
                new Page<>(page, pageSize),
                buildQueryWrapper(status, type, keyword, requesterId, runnerId));
        return buildListResponse(result, page, pageSize);
    }

    @Override
    @Transactional(readOnly = true)
    public OrderDetailResponse getOrder(Long orderId) {
        return toDetailResponse(findOrder(orderId));
    }

    @Override
    @Transactional
    public OrderDetailResponse acceptOrder(Long userId, Long orderId) {
        int affectedRows = orderDao.acceptOrder(orderId, userId, OrderStatus.OPEN, OrderStatus.ACCEPTED);
        if (affectedRows == 1) {
            Order accepted = findOrder(orderId);
            writeStatusLog(orderId, OrderStatus.OPEN, OrderStatus.ACCEPTED, userId, "骑手已接单");
            conversationService.ensureConversationBetweenUsers(accepted.getRequesterId(), userId);
            return toDetailResponse(accepted);
        }

        Order order = findOrder(orderId);
        if (order.getRequesterId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不能接自己发布的订单");
        }
        if (order.getStatus() != OrderStatus.OPEN) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "该订单已被接走或状态已变化");
        }
        throw new ResponseStatusException(HttpStatus.CONFLICT, "接单失败，请稍后重试");
    }

    @Override
    @Transactional
    public OrderDetailResponse updateOrderStatus(Long userId, Long orderId, UpdateOrderStatusRequest request) {
        Order order = findOrder(orderId);
        requireRunner(userId, order);

        OrderStatus fromStatus = order.getStatus();
        OrderStatus toStatus = request.getToStatus();
        if (fromStatus == toStatus) {
            return toDetailResponse(order);
        }

        validateRunnerTransition(fromStatus, toStatus);
        order.setStatus(toStatus);
        Order saved = orderDao.save(order);

        String note = normalizeText(request.getNote());
        if (note == null) {
            note = switch (toStatus) {
                case IN_PROGRESS -> "骑手已开始配送";
                case DELIVERED -> "骑手已标记送达";
                default -> "订单状态已更新";
            };
        }
        writeStatusLog(saved.getId(), fromStatus, toStatus, userId, note);
        return toDetailResponse(saved);
    }

    @Override
    @Transactional
    public OrderDetailResponse confirmOrder(Long userId, Long orderId) {
        Order order = findOrder(orderId);
        requireRequester(userId, order);

        if (order.getStatus() == OrderStatus.COMPLETED) {
            return toDetailResponse(order);
        }
        if (order.getStatus() != OrderStatus.DELIVERED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "只有已送达订单才能确认完成");
        }

        order.setStatus(OrderStatus.COMPLETED);
        Order saved = orderDao.save(order);
        writeStatusLog(saved.getId(), OrderStatus.DELIVERED, OrderStatus.COMPLETED, userId, "发单人已确认完成");
        return toDetailResponse(saved);
    }

    @Override
    @Transactional
    public OrderDetailResponse addDeliveryImage(Long userId, Long orderId, String imageUrl, String note) {
        Order order = findOrder(orderId);
        requireRunner(userId, order);
        if (order.getStatus() != OrderStatus.DELIVERED && order.getStatus() != OrderStatus.COMPLETED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "只有已送达或已完成订单才能上传配送凭证");
        }

        String normalizedUrl = normalizeText(imageUrl);
        if (normalizedUrl == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "配送凭证图片不能为空");
        }

        OrderDeliveryImage image = new OrderDeliveryImage();
        image.setOrderId(orderId);
        image.setUploaderId(userId);
        image.setImageUrl(normalizedUrl);
        image.setNote(normalizeText(note));
        orderDeliveryImageDao.save(image);

        conversationService.sendOrderImageMessage(userId, order.getRequesterId(), orderId, normalizedUrl, note);
        return toDetailResponse(order);
    }

    @Override
    @Transactional
    public OrderDetailResponse updateOrder(Long userId, Long orderId, UpdateOrderRequest request) {
        Order order = findOrder(orderId);
        requireRequester(userId, order);

        if (order.getStatus() != OrderStatus.OPEN) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "只有待接单订单才能修改");
        }

        validateCreateOrUpdateRequest(
                request.getExpectedTime(),
                request.getContactMode(),
                request.getContactValue());

        order.setType(request.getType());
        order.setPickupLocation(request.getPickupLocation().trim());
        order.setDropoffLocation(request.getDropoffLocation().trim());
        order.setExpectedTime(request.getExpectedTime());
        order.setRewardAmount(request.getRewardAmount());
        order.setContactMode(request.getContactMode());
        order.setContactValue(normalizeContactValue(request.getContactMode(), request.getContactValue()));
        order.setRemark(normalizeText(request.getRemark()));

        return toDetailResponse(orderDao.save(order));
    }

    @Override
    @Transactional
    public void deleteOrder(Long userId, Long orderId) {
        Order order = findOrder(orderId);
        requireRequester(userId, order);

        if (order.getStatus() != OrderStatus.OPEN) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "只有待接单订单才能删除");
        }
        orderDao.delete(order);
    }

    @Override
    @Transactional
    public OrderDetailResponse cancelOrder(Long userId, Long orderId, CancelOrderRequest request) {
        Order order = findOrder(orderId);
        String reason = normalizeText(request == null ? null : request.getReason());
        if (reason == null) {
            reason = "用户主动取消订单";
        }

        if (isFinalStatus(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "当前订单已结束，不能再次取消");
        }

        CancelledBy cancelledBy = resolveCancelRole(userId, order);
        if (cancelledBy == CancelledBy.REQUESTER) {
            return cancelByRequester(order, userId, reason);
        }

        if (order.getStatus() == OrderStatus.DELIVERED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "订单已送达，骑手不能直接取消");
        }
        return cancelDirectly(order, cancelledBy, userId, reason, "订单已直接取消");
    }

    @Override
    @Transactional
    public OrderDetailResponse approveCancelRequest(Long userId, Long orderId, HandleOrderCancelRequest request) {
        Order order = findOrder(orderId);
        requireRunner(userId, order);

        OrderCancelRequest cancelRequest = findPendingCancelRequest(orderId);
        if (order.getStatus() != OrderStatus.IN_PROGRESS) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "只有配送中的订单才能处理取消申请");
        }

        cancelRequest.setStatus(OrderCancelRequestStatus.APPROVED);
        cancelRequest.setHandledBy(userId);
        cancelRequest.setHandledAt(LocalDateTime.now());
        cancelRequest.setHandleNote(normalizeText(request == null ? null : request.getNote()));
        cancelRequest.setRunnerReadAt(LocalDateTime.now());
        cancelRequest.setRequesterReadAt(null);
        orderCancelRequestDao.save(cancelRequest);

        return cancelDirectly(order, CancelledBy.REQUESTER, userId, cancelRequest.getReason(), "骑手已同意取消申请");
    }

    @Override
    @Transactional
    public OrderDetailResponse rejectCancelRequest(Long userId, Long orderId, HandleOrderCancelRequest request) {
        Order order = findOrder(orderId);
        requireRunner(userId, order);

        OrderCancelRequest cancelRequest = findPendingCancelRequest(orderId);
        cancelRequest.setStatus(OrderCancelRequestStatus.REJECTED);
        cancelRequest.setHandledBy(userId);
        cancelRequest.setHandledAt(LocalDateTime.now());
        cancelRequest.setHandleNote(normalizeText(request == null ? null : request.getNote()));
        cancelRequest.setRunnerReadAt(LocalDateTime.now());
        cancelRequest.setRequesterReadAt(null);
        orderCancelRequestDao.save(cancelRequest);

        writeStatusLog(orderId, order.getStatus(), order.getStatus(), userId, "骑手已拒绝取消申请");
        return toDetailResponse(order);
    }

    private OrderDetailResponse cancelByRequester(Order order, Long requesterId, String reason) {
        if (order.getStatus() == OrderStatus.DELIVERED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "订单已送达，发单人不能取消");
        }

        if (order.getStatus() == OrderStatus.IN_PROGRESS) {
            createRequesterCancelRequest(order, requesterId, reason);
            return toDetailResponse(order);
        }

        if (order.getStatus() == OrderStatus.OPEN || order.getStatus() == OrderStatus.ACCEPTED) {
            return cancelDirectly(order, CancelledBy.REQUESTER, requesterId, reason, "发单人已取消订单");
        }

        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "当前订单状态不允许发单人取消");
    }

    private void createRequesterCancelRequest(Order order, Long requesterId, String reason) {
        if (order.getRunnerId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "该订单还没有骑手，无法发起配送中取消申请");
        }

        boolean hasPending = orderCancelRequestDao.findByOrderIdAndStatus(order.getId(), OrderCancelRequestStatus.PENDING)
                .isPresent();
        if (hasPending) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "该订单已有待处理的取消申请");
        }

        ensureRequesterInProgressCancelQuota(requesterId);

        OrderCancelRequest cancelRequest = new OrderCancelRequest();
        cancelRequest.setOrderId(order.getId());
        cancelRequest.setRequesterId(requesterId);
        cancelRequest.setRunnerId(order.getRunnerId());
        cancelRequest.setReason(reason);
        cancelRequest.setStatus(OrderCancelRequestStatus.PENDING);
        cancelRequest.setRequesterReadAt(LocalDateTime.now());
        cancelRequest.setRunnerReadAt(null);
        orderCancelRequestDao.save(cancelRequest);

        writeStatusLog(order.getId(), order.getStatus(), order.getStatus(), requesterId, "发单人已发起取消申请，等待骑手处理");
    }

    private void ensureRequesterInProgressCancelQuota(Long requesterId) {
        LocalDate today = LocalDate.now();
        LocalDateTime dayStart = today.atStartOfDay();
        LocalDateTime dayEnd = today.plusDays(1).atStartOfDay().minusNanos(1);
        long requestCount = orderCancelRequestDao.countByRequesterIdAndCreatedAtBetween(requesterId, dayStart, dayEnd);
        if (requestCount >= 1) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "当天已提交过配送中取消申请，请稍后再试");
        }
    }

    private OrderDetailResponse cancelDirectly(
            Order order,
            CancelledBy cancelledBy,
            Long operatorId,
            String reason,
            String logNote) {
        OrderStatus fromStatus = order.getStatus();
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledBy(cancelledBy);
        order.setCancelReason(reason);
        Order saved = orderDao.save(order);

        Optional<OrderCancelRequest> pendingRequest = orderCancelRequestDao
                .findByOrderIdAndStatus(order.getId(), OrderCancelRequestStatus.PENDING);
        if (pendingRequest.isPresent()) {
            OrderCancelRequest request = pendingRequest.get();
            request.setStatus(OrderCancelRequestStatus.REJECTED);
            request.setHandledBy(operatorId);
            request.setHandledAt(LocalDateTime.now());
            request.setHandleNote("订单已直接取消，撤销待处理申请");
            request.setRunnerReadAt(LocalDateTime.now());
            request.setRequesterReadAt(null);
            orderCancelRequestDao.save(request);
        }

        writeStatusLog(saved.getId(), fromStatus, OrderStatus.CANCELLED, operatorId, logNote + "：" + reason);
        return toDetailResponse(saved);
    }

    private OrderCancelRequest findPendingCancelRequest(Long orderId) {
        return orderCancelRequestDao.findByOrderIdAndStatus(orderId, OrderCancelRequestStatus.PENDING)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "未找到待处理的取消申请"));
    }

    private LambdaQueryWrapper<Order> buildQueryWrapper(
            OrderStatus status,
            OrderType type,
            String keyword,
            Long requesterId,
            Long runnerId) {
        LambdaQueryWrapper<Order> wrapper = Wrappers.lambdaQuery();
        if (status != null) {
            wrapper.eq(Order::getStatus, status);
        }
        if (type != null) {
            wrapper.eq(Order::getType, type);
        }
        if (requesterId != null) {
            wrapper.eq(Order::getRequesterId, requesterId);
        }
        if (runnerId != null) {
            wrapper.eq(Order::getRunnerId, runnerId);
        }
        if (keyword != null && !keyword.isBlank()) {
            String normalizedKeyword = keyword.trim();
            wrapper.and(group -> group.like(Order::getPickupLocation, normalizedKeyword)
                    .or()
                    .like(Order::getDropoffLocation, normalizedKeyword)
                    .or()
                    .like(Order::getRemark, normalizedKeyword));
        }
        wrapper.orderByDesc(Order::getCreatedAt);
        return wrapper;
    }

    private OrderListResponse buildListResponse(Page<Order> result, int page, int pageSize) {
        Map<Long, User> requesterMap = loadRequesterMap(result.getRecords());
        List<OrderSummaryResponse> list = result.getRecords().stream()
                .map(order -> toSummaryResponse(order, requesterMap.get(order.getRequesterId())))
                .toList();

        OrderListResponse response = new OrderListResponse();
        response.setList(list);
        response.setTotal(result.getTotal());
        response.setPage(page);
        response.setPageSize(pageSize);
        return response;
    }

    private void validateCreateOrUpdateRequest(LocalDateTime expectedTime, ContactMode contactMode, String contactValue) {
        if (expectedTime == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "期望完成时间不能为空");
        }
        LocalDateTime minAllowedTime = LocalDateTime.now().minusMinutes(10);
        if (expectedTime.isBefore(minAllowedTime)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "期望完成时间不能早于当前时间前 10 分钟");
        }
        if (contactMode == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "联系形式不能为空");
        }
        if (contactMode == ContactMode.PHONE && normalizeText(contactValue) == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "选择电话联系时必须填写联系电话");
        }
    }

    private void validateRunnerTransition(OrderStatus fromStatus, OrderStatus toStatus) {
        if (fromStatus == OrderStatus.ACCEPTED && toStatus == OrderStatus.IN_PROGRESS) {
            return;
        }
        if (fromStatus == OrderStatus.IN_PROGRESS && toStatus == OrderStatus.DELIVERED) {
            return;
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不支持的订单状态变更：" + fromStatus + " -> " + toStatus);
    }

    private void requireRequester(Long userId, Order order) {
        if (!order.getRequesterId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有发单人可以执行该操作");
        }
    }

    private void requireRunner(Long userId, Order order) {
        if (order.getRunnerId() == null || !order.getRunnerId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有当前接单骑手可以执行该操作");
        }
    }

    private CancelledBy resolveCancelRole(Long userId, Order order) {
        if (order.getRequesterId().equals(userId)) {
            return CancelledBy.REQUESTER;
        }
        if (order.getRunnerId() != null && order.getRunnerId().equals(userId)) {
            return CancelledBy.RUNNER;
        }
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "当前用户无权取消该订单");
    }

    private boolean isFinalStatus(OrderStatus status) {
        return status == OrderStatus.CANCELLED
                || status == OrderStatus.COMPLETED
                || status == OrderStatus.EXPIRED;
    }

    private String normalizeContactValue(ContactMode contactMode, String contactValue) {
        if (contactMode == ContactMode.IN_APP) {
            return null;
        }
        return normalizeText(contactValue);
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private void writeStatusLog(Long orderId, OrderStatus fromStatus, OrderStatus toStatus, Long operatorId, String note) {
        OrderStatusLog log = new OrderStatusLog();
        log.setOrderId(orderId);
        log.setFromStatus(fromStatus);
        log.setToStatus(toStatus);
        log.setOperatorId(operatorId);
        log.setNote(note);
        orderStatusLogDao.save(log);
    }

    private OrderSummaryResponse toSummaryResponse(Order order, User requester) {
        OrderSummaryResponse response = new OrderSummaryResponse();
        response.setId(order.getId());
        response.setRequesterId(order.getRequesterId());
        applyRequesterInfo(response, requester);
        response.setRunnerId(order.getRunnerId());
        response.setType(order.getType());
        response.setPickupLocation(order.getPickupLocation());
        response.setDropoffLocation(order.getDropoffLocation());
        response.setExpectedTime(order.getExpectedTime());
        response.setRewardAmount(order.getRewardAmount());
        response.setStatus(order.getStatus());
        response.setCreatedAt(order.getCreatedAt());
        return response;
    }

    private OrderDetailResponse toDetailResponse(Order order) {
        User requester = userDao.findById(order.getRequesterId()).orElse(null);

        OrderDetailResponse response = new OrderDetailResponse();
        response.setId(order.getId());
        response.setRequesterId(order.getRequesterId());
        applyRequesterInfo(response, requester);
        response.setRunnerId(order.getRunnerId());
        response.setType(order.getType());
        response.setPickupLocation(order.getPickupLocation());
        response.setDropoffLocation(order.getDropoffLocation());
        response.setExpectedTime(order.getExpectedTime());
        response.setRewardAmount(order.getRewardAmount());
        response.setContactMode(order.getContactMode());
        response.setContactValue(order.getContactValue());
        response.setRemark(order.getRemark());
        response.setStatus(order.getStatus());
        response.setCancelledBy(order.getCancelledBy());
        response.setCancelReason(order.getCancelReason());
        response.setCancelRequest(orderCancelRequestDao.findTopByOrderIdOrderByCreatedAtDesc(order.getId())
                .map(this::toCancelRequestResponse)
                .orElse(null));
        response.setDeliveryImages(orderDeliveryImageDao.findByOrderIdOrderByCreatedAtDesc(order.getId()).stream()
                .map(this::toDeliveryImageResponse)
                .toList());
        response.setCreatedAt(order.getCreatedAt());
        response.setUpdatedAt(order.getUpdatedAt());
        return response;
    }

    private void applyRequesterInfo(OrderSummaryResponse response, User requester) {
        if (requester == null) {
            return;
        }
        response.setRequesterUsername(requester.getUsername());
        response.setRequesterNickname(requester.getNickname());
        response.setRequesterAvatarUrl(requester.getAvatarUrl());
    }

    private void applyRequesterInfo(OrderDetailResponse response, User requester) {
        if (requester == null) {
            return;
        }
        response.setRequesterUsername(requester.getUsername());
        response.setRequesterNickname(requester.getNickname());
        response.setRequesterAvatarUrl(requester.getAvatarUrl());
    }

    private Map<Long, User> loadRequesterMap(List<Order> orders) {
        if (orders == null || orders.isEmpty()) {
            return Map.of();
        }
        return userDao.findAllById(orders.stream()
                .map(Order::getRequesterId)
                .distinct()
                .toList()).stream()
                .collect(Collectors.toMap(User::getId, Function.identity(), (left, right) -> left));
    }

    private OrderCancelRequestResponse toCancelRequestResponse(OrderCancelRequest request) {
        OrderCancelRequestResponse response = new OrderCancelRequestResponse();
        response.setId(request.getId());
        response.setOrderId(request.getOrderId());
        response.setRequesterId(request.getRequesterId());
        response.setRunnerId(request.getRunnerId());
        response.setReason(request.getReason());
        response.setStatus(request.getStatus());
        response.setHandledBy(request.getHandledBy());
        response.setHandleNote(request.getHandleNote());
        response.setHandledAt(request.getHandledAt());
        response.setCreatedAt(request.getCreatedAt());
        response.setUpdatedAt(request.getUpdatedAt());
        return response;
    }

    private OrderDeliveryImageResponse toDeliveryImageResponse(OrderDeliveryImage image) {
        OrderDeliveryImageResponse response = new OrderDeliveryImageResponse();
        response.setId(image.getId());
        response.setOrderId(image.getOrderId());
        response.setUploaderId(image.getUploaderId());
        response.setImageUrl(image.getImageUrl());
        response.setNote(image.getNote());
        response.setCreatedAt(image.getCreatedAt());
        return response;
    }

    private Order findOrder(Long orderId) {
        return orderDao.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "订单不存在"));
    }
}
