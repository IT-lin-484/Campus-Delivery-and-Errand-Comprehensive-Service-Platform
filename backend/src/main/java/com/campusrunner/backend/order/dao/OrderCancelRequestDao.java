package com.campusrunner.backend.order.dao;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.order.entity.OrderCancelRequest;
import com.campusrunner.backend.order.enums.OrderCancelRequestStatus;

/**
 * Order cancel request data access interface.
 */
public interface OrderCancelRequestDao extends BaseDao<OrderCancelRequest> {

    Optional<OrderCancelRequest> findByOrderIdAndStatus(
            @Param("orderId") Long orderId,
            @Param("status") OrderCancelRequestStatus status);

    Optional<OrderCancelRequest> findTopByOrderIdOrderByCreatedAtDesc(@Param("orderId") Long orderId);

    long countByRequesterIdAndCreatedAtBetween(
            @Param("requesterId") Long requesterId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    long countByRunnerIdAndStatusAndRunnerReadAtIsNull(
            @Param("runnerId") Long runnerId,
            @Param("status") OrderCancelRequestStatus status);

    long countByRequesterIdAndStatusInAndRequesterReadAtIsNull(
            @Param("requesterId") Long requesterId,
            @Param("statuses") Collection<OrderCancelRequestStatus> statuses);

    List<OrderCancelRequest> findTop20ByRunnerIdAndStatusOrderByCreatedAtDesc(
            @Param("runnerId") Long runnerId,
            @Param("status") OrderCancelRequestStatus status);

    List<OrderCancelRequest> findTop20ByRequesterIdAndStatusInOrderByHandledAtDesc(
            @Param("requesterId") Long requesterId,
            @Param("statuses") Collection<OrderCancelRequestStatus> statuses);

    int markRunnerUnreadAsRead(
            @Param("runnerId") Long runnerId,
            @Param("status") OrderCancelRequestStatus status,
            @Param("readAt") LocalDateTime readAt);

    int markRequesterUnreadAsRead(
            @Param("requesterId") Long requesterId,
            @Param("statuses") Collection<OrderCancelRequestStatus> statuses,
            @Param("readAt") LocalDateTime readAt);
}
