package com.campusrunner.backend.order.dao;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.order.entity.OrderDeliveryImage;

/**
 * Order delivery image data access interface.
 */
public interface OrderDeliveryImageDao extends BaseDao<OrderDeliveryImage> {

    List<OrderDeliveryImage> findByOrderIdOrderByCreatedAtDesc(@Param("orderId") Long orderId);
}
