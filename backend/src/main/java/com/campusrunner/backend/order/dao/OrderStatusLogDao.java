package com.campusrunner.backend.order.dao;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.order.entity.OrderStatusLog;

/**
 * Order status log data access interface.
 */
public interface OrderStatusLogDao extends BaseDao<OrderStatusLog> {

    List<OrderStatusLog> findByOrderIdOrderByCreatedAtDesc(@Param("orderId") Long orderId);
}
