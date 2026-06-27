package com.campusrunner.backend.user.dao;

import java.util.Optional;

import org.apache.ibatis.annotations.Param;

import com.campusrunner.backend.common.dao.BaseDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * User data access interface.
 */
public interface UserDao extends BaseDao<User> {

    boolean existsByUsername(@Param("username") String username);

    Optional<User> findByUsername(@Param("username") String username);

    long countByStatus(@Param("status") UserStatus status);
}
