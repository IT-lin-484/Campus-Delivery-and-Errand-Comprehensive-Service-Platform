package com.campusrunner.backend.order.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
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
import com.campusrunner.backend.order.dao.OrderCancelRequestDao;
import com.campusrunner.backend.order.dao.OrderDeliveryImageDao;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.order.dao.OrderStatusLogDao;

public interface OrderService {
    OrderDetailResponse createOrder(Long requesterId, CreateOrderRequest request);
    OrderListResponse listOrders(OrderStatus status, OrderType type, String keyword, int page, int pageSize);
    OrderListResponse listMyOrders(Long userId, String as, OrderStatus status, OrderType type, String keyword, int page, int pageSize);
    OrderDetailResponse getOrder(Long orderId);
    OrderDetailResponse acceptOrder(Long userId, Long orderId);
    OrderDetailResponse updateOrderStatus(Long userId, Long orderId, UpdateOrderStatusRequest request);
    OrderDetailResponse confirmOrder(Long userId, Long orderId);
    OrderDetailResponse addDeliveryImage(Long userId, Long orderId, String imageUrl, String note);
    OrderDetailResponse updateOrder(Long userId, Long orderId, UpdateOrderRequest request);
    void deleteOrder(Long userId, Long orderId);
    OrderDetailResponse cancelOrder(Long userId, Long orderId, CancelOrderRequest request);
    OrderDetailResponse approveCancelRequest(Long userId, Long orderId, HandleOrderCancelRequest request);
    OrderDetailResponse rejectCancelRequest(Long userId, Long orderId, HandleOrderCancelRequest request);
}

