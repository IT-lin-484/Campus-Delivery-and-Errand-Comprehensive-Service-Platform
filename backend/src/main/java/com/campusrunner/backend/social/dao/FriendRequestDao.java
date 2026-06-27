package com.campusrunner.backend.social.dao;

import java.util.List;
import java.util.Optional;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.social.entity.FriendRequest;
import com.campusrunner.backend.social.enums.FriendRequestStatus;

/**
 * Friend request data access interface.
 */
public interface FriendRequestDao extends BaseDao<FriendRequest> {

    Optional<FriendRequest> findTopByFromUserIdAndToUserIdAndStatusOrderByCreatedAtDesc(
            @Param("fromUserId") Long fromUserId,
            @Param("toUserId") Long toUserId,
            @Param("status") FriendRequestStatus status);

    List<FriendRequest> findByToUserIdOrderByCreatedAtDesc(@Param("toUserId") Long toUserId);

    List<FriendRequest> findByFromUserIdOrderByCreatedAtDesc(@Param("fromUserId") Long fromUserId);

    long countByToUserIdAndStatus(
            @Param("toUserId") Long toUserId,
            @Param("status") FriendRequestStatus status);
}
