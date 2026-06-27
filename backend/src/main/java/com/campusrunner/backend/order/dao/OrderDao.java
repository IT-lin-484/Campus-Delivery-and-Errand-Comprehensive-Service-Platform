package com.campusrunner.backend.order.dao;

import java.util.Collection;
import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.order.entity.Order;
import com.campusrunner.backend.order.enums.OrderStatus;

/**
 * Order data access interface.
 */
public interface OrderDao extends BaseDao<Order> {

    int acceptOrder(
            @Param("orderId") Long orderId,
            @Param("runnerId") Long runnerId,
            @Param("openStatus") OrderStatus openStatus,
            @Param("acceptedStatus") OrderStatus acceptedStatus);

    long countByRequesterId(@Param("requesterId") Long requesterId);

    long countByRunnerId(@Param("runnerId") Long runnerId);

    long countByStatus(@Param("status") OrderStatus status);

    long countByRequesterIdAndStatuses(
            @Param("requesterId") Long requesterId,
            @Param("statuses") List<OrderStatus> statuses);

    long countByRunnerIdAndStatuses(
            @Param("runnerId") Long runnerId,
            @Param("statuses") List<OrderStatus> statuses);

    long countByAbnormalFlagTrue();

    boolean existsCommunicationOrderBetweenUsers(
            @Param("userAId") Long userAId,
            @Param("userBId") Long userBId,
            @Param("statuses") Collection<OrderStatus> statuses);
}
