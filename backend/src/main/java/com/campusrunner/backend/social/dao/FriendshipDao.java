package com.campusrunner.backend.social.dao;

import java.util.List;
import java.util.Optional;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.social.entity.Friendship;
import com.campusrunner.backend.social.enums.FriendshipStatus;

/**
 * Friendship data access interface.
 */
public interface FriendshipDao extends BaseDao<Friendship> {

    boolean existsByUserIdAndFriendUserIdAndStatus(
            @Param("userId") Long userId,
            @Param("friendUserId") Long friendUserId,
            @Param("status") FriendshipStatus status);

    Optional<Friendship> findByUserIdAndFriendUserIdAndStatus(
            @Param("userId") Long userId,
            @Param("friendUserId") Long friendUserId,
            @Param("status") FriendshipStatus status);

    List<Friendship> findByUserIdAndStatusOrderByUpdatedAtDesc(
            @Param("userId") Long userId,
            @Param("status") FriendshipStatus status);

    int deleteByUserIdAndFriendUserId(
            @Param("userId") Long userId,
            @Param("friendUserId") Long friendUserId);
}
