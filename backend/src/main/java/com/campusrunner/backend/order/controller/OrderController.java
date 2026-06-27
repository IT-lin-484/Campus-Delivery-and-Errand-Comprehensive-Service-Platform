package com.campusrunner.backend.order.controller;

import org.springframework.http.MediaType;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import com.campusrunner.backend.auth.service.CurrentUserService;
import com.campusrunner.backend.order.dto.CancelOrderRequest;
import com.campusrunner.backend.order.dto.CreateOrderRequest;
import com.campusrunner.backend.order.dto.HandleOrderCancelRequest;
import com.campusrunner.backend.order.dto.OrderDetailResponse;
import com.campusrunner.backend.order.dto.OrderListResponse;
import com.campusrunner.backend.order.dto.UpdateOrderRequest;
import com.campusrunner.backend.order.dto.UpdateOrderStatusRequest;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.order.enums.OrderType;
import com.campusrunner.backend.order.service.OrderDeliveryImageStorageService;
import com.campusrunner.backend.order.service.OrderService;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 鐢ㄦ埛渚ц鍗曟帴鍙ｃ€? */
@Validated
@RestController
@RequestMapping("/api/v1")
public class OrderController {

    private final OrderService orderService;
    private final CurrentUserService currentUserService;
    private final OrderDeliveryImageStorageService orderDeliveryImageStorageService;

    public OrderController(
            OrderService orderService,
            CurrentUserService currentUserService,
            OrderDeliveryImageStorageService orderDeliveryImageStorageService) {
        this.orderService = orderService;
        this.currentUserService = currentUserService;
        this.orderDeliveryImageStorageService = orderDeliveryImageStorageService;
    }

    @PostMapping("/orders")
    public OrderDetailResponse createOrder(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @Valid @RequestBody CreateOrderRequest request) {
        Long requesterId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.createOrder(requesterId, request);
    }

    @GetMapping("/orders")
    public OrderListResponse listOrders(
            @RequestParam(value = "status", required = false) OrderStatus status,
            @RequestParam(value = "type", required = false) OrderType type,
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "10") @Min(1) @Max(100) int pageSize) {
        return orderService.listOrders(status, type, keyword, page, pageSize);
    }

    @GetMapping("/orders/{id}")
    public OrderDetailResponse getOrder(@PathVariable("id") Long id) {
        return orderService.getOrder(id);
    }

    @PostMapping("/orders/{id}/accept")
    public OrderDetailResponse acceptOrder(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.acceptOrder(currentUserId, id);
    }

    @PostMapping("/orders/{id}/status")
    public OrderDetailResponse updateOrderStatus(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id,
            @Valid @RequestBody UpdateOrderStatusRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.updateOrderStatus(currentUserId, id, request);
    }

    @PostMapping("/orders/{id}/confirm")
    public OrderDetailResponse confirmOrder(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.confirmOrder(currentUserId, id);
    }

    @PostMapping(value = "/orders/{id}/delivery-images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public OrderDetailResponse uploadDeliveryImage(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id,
            @RequestPart("file") MultipartFile file,
            @RequestPart(value = "note", required = false) String note) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);

        String relativePath = orderDeliveryImageStorageService.storeImage(file);
        String publicUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path(relativePath)
                .toUriString();
        return orderService.addDeliveryImage(currentUserId, id, publicUrl, note);
    }

    @PatchMapping("/orders/{id}")
    public OrderDetailResponse updateOrder(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id,
            @Valid @RequestBody UpdateOrderRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.updateOrder(currentUserId, id, request);
    }

    @DeleteMapping("/orders/{id}")
    public void deleteOrder(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        orderService.deleteOrder(currentUserId, id);
    }

    @PostMapping("/orders/{id}/cancel")
    public OrderDetailResponse cancelOrder(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id,
            @Valid @RequestBody(required = false) CancelOrderRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.cancelOrder(currentUserId, id, request);
    }

    @PostMapping("/orders/{id}/cancel/approve")
    public OrderDetailResponse approveCancelRequest(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id,
            @Valid @RequestBody(required = false) HandleOrderCancelRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.approveCancelRequest(currentUserId, id, request);
    }

    @PostMapping("/orders/{id}/cancel/reject")
    public OrderDetailResponse rejectCancelRequest(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long id,
            @Valid @RequestBody(required = false) HandleOrderCancelRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.rejectCancelRequest(currentUserId, id, request);
    }

    @GetMapping("/me/orders")
    public OrderListResponse listMyOrders(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestParam(value = "as", defaultValue = "requester") String as,
            @RequestParam(value = "status", required = false) OrderStatus status,
            @RequestParam(value = "type", required = false) OrderType type,
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "10") @Min(1) @Max(100) int pageSize) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return orderService.listMyOrders(currentUserId, as, status, type, keyword, page, pageSize);
    }
}

